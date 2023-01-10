//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

// Openzeppelin libraries
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/INFTStaking.sol";
import "./interfaces/IBoosterController.sol";

/**
 * @dev Stake TAVA token with locked staking option
 * and distribute third-party token
 */
contract SmartChef is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20Metadata;

    /**
     *  @dev Structs to store user staking data.
     */
    struct UserInfo {
        uint256 lockedAmount; // locked amount
        uint256 lockStartTime; // locked at.
        uint256 lockEndTime; // unlock at
        bool locked; //lock status.
        uint256 rewards; // rewards
        uint256 rewardDebt; // rewards debt
    }

    // The address of the smart chef factory
    address public immutable masterSmartChefFactory;
    // Booster controller
    IBoosterController public boosterController;

    // stakedToken
    IERC20Metadata public stakedToken;
    // rewardToken
    IERC20Metadata public rewardToken;
    // reward token from another network
    string public reward;
    // Second Skin NFT Staking Contract
    INFTStaking public nftstaking;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    /// @notice Reward token should be airdrop or not
    /// Since reward token is coming from several networks
    /// reward token might be airdropped
    /// If reward token is coming from ethereum network,
    /// Users can claim from our contract directly
    bool public rewardByAirdrop = true;

    // The precision factor
    uint256 public precisionFactor;
    // Whether it is initialized
    bool public isInitialized;
    // Accrued token per share
    uint256 public accTokenPerShare;
    // The block number when third-party rewardToken mining ends.
    uint256 public bonusEndBlock;
    // The block number when third-party rewardToken mining starts.
    uint256 public startBlock;
    // The block number of the last pool update
    uint256 public lastRewardBlock;
    // third-party rewardToken created per block.
    uint256 public rewardPerBlock;

    // Booster denominator
    uint256 public constant DENOMINATOR = 10000 * 365 days; // 100% * 365 days
    // Limit lock period on min-max level
    uint256 public constant MIN_LOCK_DURATION = 1 days;
    uint256 public constant MAX_LOCK_DURATION = 1000 days;
    // Min deposit able amount
    uint256 public constant MIN_DEPOSIT_AMOUNT = 0.00001 ether;

    event NewRewardPerBlock(uint256 rewardPerBlock);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);

    /// @notice whenever user lock or extend period, emit
    /// @param smartchef: smartchef contract address
    /// @param sender: staker/user wallet address
    /// @param lockedAmount: locked amount
    /// @param lockStartTime: locked at
    /// @param lockEndTime: unlock at
    /// @param rewards: reward amount
    /// @param rewardDebt: reward debt
    event Stake(
        address smartchef,
        address sender,
        uint256 lockedAmount,
        uint256 lockStartTime,
        uint256 lockEndTime,
        uint256 rewards,
        uint256 rewardDebt
    );

    /// @notice whenever user lock or extend period, emit
    /// @param smartchef: smartchef contract address
    /// @param sender: staker/user wallet address
    /// @param rewards: reward amount
    /// @param boosterValue: boosted apr
    /// @param airdropWalletAddress: airdrop wallet address
    event Unstaked(
        address smartchef,
        address sender,
        uint256 rewards,
        uint256 boosterValue,
        string airdropWalletAddress
    );

    /// @notice contructor
    /// Here, msg.sender is MasterChef contract address
    /// since MasterChef deploy this contract
    constructor() {
        masterSmartChefFactory = msg.sender;
    }

    /**
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _reward: Reward token address. This can be used in case
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _bonusEndBlock: end block
     * @param _rewardByAirdrop: If reward token is coming from other chains
     * In this case, reward token would be airdropped
     */
    function initialize(
        IERC20Metadata _stakedToken,
        IERC20Metadata _rewardToken,
        string memory _reward,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        address _newOwner,
        address _nftstaking,
        bool _rewardByAirdrop,
        address _boosterController
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == masterSmartChefFactory, "Not factory");
        require(_boosterController != address(0x0), "Cannot be zero address");

        boosterController = IBoosterController(_boosterController);
        // Make this contract initialized
        isInitialized = true;

        stakedToken = _stakedToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        rewardByAirdrop = _rewardByAirdrop;

        // If reward token is claimable
        if (!_rewardByAirdrop) {
            rewardToken = _rewardToken;
            uint256 decimalsRewardToken = uint256(rewardToken.decimals());
            require(decimalsRewardToken < 30, "Must be less than 30");
            precisionFactor = uint256(
                10 ** (uint256(30) - decimalsRewardToken)
            );
        } else {
            precisionFactor = uint256(10 ** (uint256(30) - 18));
        }
        reward = _reward;

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;
        // nft staking
        nftstaking = INFTStaking(_nftstaking);

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_newOwner);
    }

    /**
     * @notice set/update BoosterController address
     */
    function setBoosterController(
        address _boosterController
    ) external onlyOwner {
        require(_boosterController != address(0x0), "Cannot be zero address");
        boosterController = IBoosterController(_boosterController);
    }

    /**
     * @notice Pause staking
     */
    function setPause(bool _isPaused) external onlyOwner {
        if (_isPaused) _pause();
        else _unpause();
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     * @param _bonusEndBlock: the new end block
     */
    function updateStartAndEndBlocks(
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        require(_startBlock < _bonusEndBlock, "startBlock too higher");
        require(block.number < _startBlock, "startBlock too lower");

        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
    }

    /**
     * @notice Stake TAVA token to get rewarded with third-party nft.
     * @param _amount: amount to lock
     * @param _lockDuration: duration to lock
     */
    function stake(
        uint256 _amount,
        uint256 _lockDuration
    ) external nonReentrant whenNotPaused returns (bool) {
        require(_amount > 0 || _lockDuration > 0, "Nothing to deposit");
        return (_stake(_amount, _lockDuration, msg.sender));
    }

    /**
     * @notice Unlock staked tokens (Unlock)
     * @dev user side withdraw manually
     * @param airdropWalletAddress: some reward tokens are from other chains
     * so users cannot claim reward directly
     * To get reward tokens, they need to provide airdrop address
     */
    function unlock(
        string memory airdropWalletAddress
    ) external nonReentrant returns (bool) {
        if (rewardByAirdrop) {
            bytes memory stringBytes = bytes(airdropWalletAddress); // Uses memory

            require(stringBytes.length > 0, "Cannot be zero address");
        }

        address _user = msg.sender;
        UserInfo storage user = userInfo[_user];
        uint256 _amount = user.lockedAmount;
        // set zero
        user.lockedAmount = 0;

        require(_amount > 0, "Empty to unlock");
        require(user.locked, "Already unlocked");
        require(user.lockEndTime < block.timestamp, "Still in locked");

        _updatePool();

        uint256 pending = (_amount * accTokenPerShare) /
            precisionFactor -
            user.rewardDebt;
        if (pending > 0) {
            user.rewards = user.rewards + pending;
        }

        // set zero
        user.locked = false;
        user.rewardDebt = 0;

        // unlock staked token
        stakedToken.safeTransfer(address(_user), _amount);
        uint256 lockDuration = user.lockEndTime - user.lockStartTime;

        uint256 boostedAPR = getStakerBoosterValue(_user);
        require(nftstaking.unstakeFromSmartChef(_user), "Unstake failed");
        uint256 rewardAmount = user.rewards +
            (user.rewards * boostedAPR) /
            (DENOMINATOR * lockDuration);

        user.rewards = 0;

        // Here, should be check pool balance as well as
        // For aidrop token, it would be done by admin automatically
        if (!rewardByAirdrop && rewardAmount > 0) {
            require(
                rewardToken.balanceOf(address(this)) >= rewardAmount,
                "Insufficient pool"
            );

            rewardToken.safeTransfer(address(_user), rewardAmount);
        }

        emit Unstaked(
            address(this),
            _user,
            rewardAmount,
            boostedAPR,
            airdropWalletAddress
        );

        return true;
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(rewardToken != stakedToken, "Not able to withdraw");
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }

    /**
     * @notice get booster APR of sender wallet.
     * @dev this value need to be divided by (365 days in second) booster denominator
     * and user's locked duration
     */
    function getStakerBoosterValue(
        address sender
    ) public view returns (uint256) {
        (uint256[] memory lockTs, uint256[] memory amounts) = nftstaking
            .getSmartChefBoostData(sender, address(this));
        UserInfo memory user = userInfo[sender];

        uint256 len = lockTs.length;

        uint256 totalAPR = 0;
        for (uint256 i = 0; i < len; i++) {
            uint256 lockTs1 = lockTs[i];
            uint256 lockTs2 = 0;
            if (i < len - 1) {
                lockTs2 = lockTs[i + 1];
            } else lockTs2 = user.lockEndTime;

            totalAPR += _getBoostAPR(
                user.lockEndTime,
                lockTs1,
                lockTs2,
                amounts[i]
            );
        }

        return totalAPR;
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     * @dev update accTokenPerShare
     */
    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

        if (stakedTokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 tavaReward = multiplier * rewardPerBlock;
        accTokenPerShare =
            accTokenPerShare +
            (tavaReward * precisionFactor) /
            stakedTokenSupply;
        lastRewardBlock = block.number;
    }

    /**
     * @notice process staking
     */
    function _stake(
        uint256 _amount,
        uint256 _lockDuration,
        address _user
    ) internal returns (bool) {
        UserInfo storage user = userInfo[_user];
        uint256 currentLockedAmount = _amount;
        // which means extend days
        if (user.lockEndTime >= block.timestamp) {
            require(_amount == 0, "Extend lock duration");
            require(
                _lockDuration > user.lockEndTime - user.lockStartTime,
                "Not enough duration to extends"
            );
            currentLockedAmount = user.lockedAmount;
        } else {
            // when user deposit newly
            require(!user.locked, "Unlock previous one");
            user.lockStartTime = block.timestamp;
        }

        require(
            _lockDuration >= MIN_LOCK_DURATION,
            "Minimum lock period is one week"
        );
        require(
            _lockDuration <= MAX_LOCK_DURATION,
            "Maximum lock period exceeded"
        );

        // Only notify at first time but not for extends
        if (_amount > 0) {
            // Notify TAVA staking to nftstaking contract
            require(nftstaking.stakeFromSmartChef(_user), "NFTStaking failed");
        }

        _updatePool();

        if (user.lockedAmount > 0) {
            uint256 pending = (user.lockedAmount * accTokenPerShare) /
                precisionFactor -
                user.rewardDebt;
            if (pending > 0) {
                user.rewards = user.rewards + pending;
            }
        }

        if (_amount > 0) {
            user.lockedAmount = user.lockedAmount + _amount;
            stakedToken.safeTransferFrom(
                address(_user),
                address(this),
                _amount
            );
        }

        user.rewardDebt =
            (user.lockedAmount * accTokenPerShare) /
            precisionFactor;
        user.lockEndTime = user.lockStartTime + _lockDuration;
        user.locked = true;

        emit Stake(
            address(this),
            _user,
            _amount,
            user.lockStartTime,
            user.lockEndTime,
            user.rewards,
            user.rewardDebt
        );
        return true;
    }

    /**
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(
        uint256 _from,
        uint256 _to
    ) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to - _from;
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock - _from;
        }
    }

    /**
     * @notice calculate APR based on how many secondskin NFT staked
     * when they are staked, how long they has been staked for smartchef pool
     */
    function _getBoostAPR(
        uint256 unlockTs,
        uint256 lockTs1,
        uint256 lockTs2,
        uint256 amount
    ) private view returns (uint256) {
        uint256 boostAPR = boosterController.getBoosterAPR(
            amount,
            address(this)
        );

        uint256 lockDuration = 0;
        if (unlockTs > lockTs2) {
            lockDuration = lockTs2 - lockTs1;
        } else if (unlockTs < lockTs1) {
            lockDuration = 0;
        } else {
            lockDuration = unlockTs - lockTs1;
        }

        return (lockDuration * boostAPR);
    }
}
