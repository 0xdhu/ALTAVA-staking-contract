//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/INFTMasterChef.sol";
import "./interfaces/INFTStaking.sol";

/**
 * @dev This NFTChef airdrops yummy third-party NFT to TAVA token stakers.
 */
contract NFTChef is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // User stake info
    struct StakerInfo {
        uint256 lockedAmount;
        uint256 lockDuration;
        uint256 rewardAmount;
        uint256 lockedAt;
        uint256 unlockAt;
        uint256 lockedNFTAmount;
        bool unstaked;
    }

    struct ChefConfig {
        uint256 requiredLockAmount;
        uint256 rewardNFTAmount;
        bool isLive;
    }

    // The address of the smart chef factory
    address public immutable nftMasterChefFactory;

    // Second Skin NFT Staking Contract
    INFTStaking public nftstaking;

    // TAVA ERC20 token
    IERC20 public stakedToken;
    // NFT token for airdrop
    string public rewardNFT;
    // Whether it is initialized
    bool public isInitialized;

    // User's staking info on index
    mapping(address => mapping(uint256 => StakerInfo)) private _stakerInfos;
    // How many staker participated on staking
    mapping(address => uint256) private _userStakeIndex;

    // Required TAVA amount based on Locked period options
    // Period (days) => ChefConfig
    mapping(uint256 => ChefConfig) public chefConfig;

    // Booster values
    // holding amount => booster percent
    // Percent real value: need to divide by 100. ex: 152 means 1.52%
    // index => value
    mapping(uint256 => uint256) private _boosters;
    // booster total number
    uint256 public boosterTotal;
    // Booster denominator
    uint256 public constant DENOMINATOR = 10000;

    /// @notice whenever user lock TAVA, emit evemt
    /// @param nftchef: nftchef contract address
    /// @param sender: staker/user wallet address
    /// @param stakeIndex: staking index
    /// @param stakedAmount: locked amount
    /// @param lockedAt: locked at
    /// @param lockDuration: lock duration
    /// @param unlockAt: unlock at
    /// @param nftBalance: registered secondskin NFT balance
    /// @param discountRate: discount rate by booster
    event Staked(
        address nftchef,
        address sender,
        uint256 stakeIndex,
        uint256 stakedAmount,
        uint256 lockedAt,
        uint256 lockDuration,
        uint256 unlockAt,
        uint256 nftBalance,
        uint256 discountRate
    );

    /// @notice Unstaked Event whenever user lock TAVA, emit evemt
    /// @param nftchef: nftchef contract address
    /// @param sender: staker/user wallet address
    /// @param stakeIndex: staking index
    /// @param rewardAmount: claimed amount
    /// @param nftBalance: registered secondskin NFT balance
    /// @param airdropWalletAddress: airdrop wallet address
    event Unstaked(
        address nftchef,
        address sender,
        uint256 stakeIndex,
        uint256 rewardAmount,
        uint256 nftBalance,
        string airdropWalletAddress
    );

    /// @notice Event whenever updates the "Required Lock Amount"
    /// @param nftchef: nftchef contract address
    /// @param sender: staker/user wallet address
    /// @param period: lock duration
    /// @param requiredAmount: required TAVA amount
    /// @param rewardnftAmount: reward nft amount
    /// @param isLive: this option is live or not
    event AddedRequiredLockAmount(
        address nftchef,
        address sender,
        uint256 period,
        uint requiredAmount,
        uint rewardnftAmount,
        bool isLive
    );

    /// @notice Constructor (initialize some configurations)
    constructor() {
        nftMasterChefFactory = msg.sender;
    }

    /*
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _rewardNFT: reward token address (airdrop NFT)
     * @param _newOwner: need to set new owner because now factory is owner
     * @param _nftstaking: NFT to be used as booster active
     * @param _booster: booster values.
     */
    function initialize(
        address _stakedToken,
        string memory _rewardNFT,
        address _newOwner,
        address _nftstaking,
        uint256[] calldata _booster
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == nftMasterChefFactory, "Not factory");

        // Make this contract initialized
        isInitialized = true;

        stakedToken = IERC20(_stakedToken);
        rewardNFT = _rewardNFT;
        nftstaking = INFTStaking(_nftstaking);

        // If didnot stake any amount of NFT, booster is just zero
        _boosters[0] = 0;
        for (uint256 i = 0; i < _booster.length; i++) {
            _boosters[i + 1] = _booster[i];
        }
        boosterTotal = _booster.length;

        /// Transfer ownership to the admin address
        /// who becomes owner of the contract
        transferOwnership(_newOwner);
    }

    /**
     * @notice Pause staking
     */
    function setPause(bool _isPaused) external onlyOwner {
        if (_isPaused) _pause();
        else _unpause();
    }

    /**
     * @dev set booster value on index
     */
    function setBoosterValue(uint256 idx, uint256 value) external onlyOwner {
        if (boosterTotal > 0 && idx == boosterTotal && value == 0) {
            delete _boosters[idx];
            boosterTotal = boosterTotal - 1;
            return;
        }
        require(idx <= boosterTotal + 1, "Out of index");
        require(idx > 0, "Index should not be zero");
        require(value > 0, "Booster value should not be zero");
        require(value < 5000, "Booster rate: overflow 50%");
        require(_boosters[idx] != value, "Amount in use");
        _boosters[idx] = value;
        if (idx == boosterTotal + 1) boosterTotal = boosterTotal + 1;

        if (idx > 1 && idx <= boosterTotal) {
            require(
                _boosters[idx] >= _boosters[idx - 1],
                "Booster value: invalid"
            );
            if (idx < boosterTotal) {
                require(
                    _boosters[idx + 1] >= _boosters[idx],
                    "Booster value: invalid"
                );
            }
        } else if (idx == 1 && boosterTotal > 1) {
            require(
                _boosters[idx + 1] >= _boosters[idx],
                "Booster value: invalid"
            );
        }
    }

    /**
     * @dev Admin should be able to set required lock amount based on lock period
     * @param _lockPeriod: Lock duration
     * @param _requiredAmount: Required lock amount to
     *  participate on staking period related option.
     * @param _rewardNFTAmount: Reward amount of thirdparty NFT.
     */
    function setRequiredLockAmount(
        uint256 _lockPeriod,
        uint256 _requiredAmount,
        uint256 _rewardNFTAmount,
        bool _isLive
    ) external onlyOwner {
        require(_lockPeriod >= 1 days, "Lock period: at least 1 day");
        if (_isLive) {
            chefConfig[_lockPeriod] = ChefConfig(
                _requiredAmount,
                _rewardNFTAmount,
                _isLive
            );
        } else {
            chefConfig[_lockPeriod].isLive = false;
        }

        emit AddedRequiredLockAmount(
            address(this),
            msg.sender,
            _lockPeriod,
            _requiredAmount,
            _rewardNFTAmount,
            _isLive
        );
    }

    /**
     * @notice this is ERC20 locked staking to get third-party NFT airdrop
     * @dev stake function with ERC20 token. this has also extend days function as well.
     *
     * @param _lockPeriod: locked options. (i.e. 30days, 60days, 90days)
     */
    function stake(uint256 _lockPeriod) external nonReentrant whenNotPaused {
        address _sender = msg.sender;

        ChefConfig memory _chefConfig = chefConfig[_lockPeriod];
        require(_chefConfig.isLive, "This option is not in live");

        uint256 requiredAmount = _chefConfig.requiredLockAmount;
        require(requiredAmount > 0, "This option doesnot exist");

        // Get user staking index
        uint256 idx = _userStakeIndex[_sender];
        // Get object of user info
        StakerInfo storage _userInfo = _stakerInfos[_sender][idx];
        require(!_userInfo.unstaked, "Already unstaked");

        // This user have not staked yet or Extend days should be bigger than rock period
        require(_userInfo.lockDuration < _lockPeriod, "Stake: Invalid period");

        // check airdrop amount
        uint256 _rewardNFTAmount = _chefConfig.rewardNFTAmount;
        require(
            _rewardNFTAmount > _userInfo.rewardAmount,
            "Invalid airdrop amount"
        );

        // check if staking is expired and renew it or check if not yet staked
        require(
            _userInfo.unlockAt >= block.timestamp ||
                _userInfo.lockedAmount == 0,
            "Expired: renew it"
        );
        require(nftstaking.stakeFromNFTChef(_sender), "NFT staking failed");

        // Balance of secondskin NFT
        uint256 nftBalance = nftstaking.getStakedNFTCount(_sender);
        // get booster percent
        uint256 boosterValue = getBoosterValue(nftBalance);
        // decrease required amount
        uint256 _decreaseAmount = (requiredAmount * boosterValue) / DENOMINATOR;
        uint256 _requiredAmount = requiredAmount - _decreaseAmount;

        // current locked amount
        uint256 currentBalance = _userInfo.lockedAmount;
        // If required amount is bigger than current balance, need to ask more staking.
        // If not, just need to extend reward amount
        if (_requiredAmount > currentBalance) {
            // the required amount to extend locked duration
            uint256 transferAmount = _requiredAmount - currentBalance;
            // NOTE: approve token to extend allowance
            // Check token balance of sender
            require(
                stakedToken.balanceOf(_sender) >= transferAmount,
                "Token: Insufficient balance"
            );
            // transfer from sender to address(this)
            stakedToken.safeTransferFrom(
                _sender,
                address(this),
                transferAmount
            );

            // Update user Info
            _userInfo.lockedAmount = _requiredAmount;
        }

        // If this stake is first time for this sender,
        // we need to set `lockedAt` timestamp
        // If this stake is for extend days, just ignore it.
        if (_userInfo.lockDuration == 0) {
            _userInfo.lockedAt = block.timestamp;
        }

        uint256 _unlockAt = _userInfo.lockedAt + _lockPeriod;

        // Update userinfo to up-to-date info
        _userInfo.rewardAmount = _rewardNFTAmount;
        _userInfo.lockDuration = _lockPeriod;
        _userInfo.unlockAt = _unlockAt;
        _userInfo.lockedNFTAmount = nftBalance;

        emit Staked(
            address(this),
            _sender,
            idx,
            _userInfo.lockedAmount,
            _userInfo.lockedAt,
            _userInfo.lockDuration,
            _userInfo.unlockAt,
            nftBalance,
            boosterValue
        );
    }

    /**
     * @dev unstake locked tokens after lock duration manually
     * @param airdropWalletAddress: some reward NFT might come from other chains
     * so users cannot claim reward directly
     * To get reward NFT, they need to provide airdrop address
     */
    function unstake(
        string memory airdropWalletAddress,
        bool giveUp
    ) external nonReentrant {
        bytes memory stringBytes = bytes(airdropWalletAddress); // Uses memory
        require(stringBytes.length > 0, "Cannot be zero address");

        address _sender = msg.sender;
        uint256 curTs = block.timestamp;

        // Get user staking index
        uint256 idx = _userStakeIndex[_sender];
        // Get object of user info
        StakerInfo storage _userInfo = _stakerInfos[_sender][idx];

        require(_userInfo.lockedAmount > 0, "Your position not exist");
        require(_userInfo.unlockAt < curTs, "Not able to withdraw");
        require(!_userInfo.unstaked, "Already unstaked");
        // Set flag unstaked
        _userInfo.unstaked = true;

        // Neet to get required amount basis current secondskin NFT amount.
        ChefConfig memory _chefConfig = chefConfig[_userInfo.lockDuration];
        uint256 rewardAmount = _chefConfig.rewardNFTAmount;
        if (giveUp) rewardAmount = 0;

        // Balance of NFT
        uint256 nftBalance = nftstaking.getNFTChefBoostCount(
            _sender,
            address(this)
        );
        require(nftstaking.unstakeFromNFTChef(_sender), "Unstake failed");
        // use this to avoid stack too deep
        {
            uint256 requiredAmount = _chefConfig.requiredLockAmount;
            // Check pool balance
            uint curLockedAmount = _userInfo.lockedAmount;

            if (nftBalance < _userInfo.lockedNFTAmount && !giveUp) {
                // get booster percent
                uint256 boosterValue = getBoosterValue(nftBalance);
                uint256 _decreaseAmount = (requiredAmount * boosterValue) /
                    DENOMINATOR;
                uint256 _requiredAmount = requiredAmount - _decreaseAmount;

                // If require amount is bigger than current locked amount,
                // which means user transferred NFT that was used as booster
                if (_requiredAmount > curLockedAmount) {
                    uint256 _panaltyAmount = _requiredAmount - curLockedAmount;
                    require(
                        stakedToken.balanceOf(_sender) >= _panaltyAmount,
                        "Not enough for panalty"
                    );
                }
            }

            require(
                stakedToken.balanceOf(address(this)) >= curLockedAmount,
                "Token: Insufficient pool"
            );

            // increase index
            _userStakeIndex[_sender] = idx + 1;

            // safeTransfer from pool to user
            stakedToken.safeTransfer(_sender, curLockedAmount);
        }

        emit Unstaked(
            address(this),
            _sender,
            idx,
            rewardAmount,
            nftBalance,
            airdropWalletAddress
        );
    }

    /**
     * @dev get booster percent of user wallet.
     */
    function getStakerBoosterValue(
        address sender
    ) external view returns (uint256) {
        uint256 amount = nftstaking.getNFTChefBoostCount(sender, address(this));
        return getBoosterValue(amount);
    }

    /**
     * @dev get Panalty amount
     */
    function getPanaltyAmount(address sender) external view returns (uint256) {
        // Get user staking index
        uint256 idx = _userStakeIndex[sender];
        StakerInfo memory _userInfo = _stakerInfos[sender][idx];
        // Neet to get required amount basis current secondskin NFT amount.
        ChefConfig memory _chefConfig = chefConfig[_userInfo.lockDuration];
        uint256 requiredAmount = _chefConfig.requiredLockAmount;
        // Balance of NFT
        uint256 nftBalance = nftstaking.getNFTChefBoostCount(
            sender,
            address(this)
        );
        if (nftBalance >= _userInfo.lockedNFTAmount) return 0;

        // get booster percent
        uint256 boosterValue = getBoosterValue(nftBalance);
        uint256 _decreaseAmount = (requiredAmount * boosterValue) / DENOMINATOR;
        uint256 _requiredAmount = requiredAmount - _decreaseAmount;
        uint curLockedAmount = _userInfo.lockedAmount;
        if (_requiredAmount > curLockedAmount) {
            uint256 _panaltyAmount = _requiredAmount - curLockedAmount;
            return _panaltyAmount;
        }
        return 0;
    }

    /**
     * @dev get Staker Info.
     */
    function getStakerInfo(
        address sender,
        uint256 stakingIndex
    ) external view returns (StakerInfo memory) {
        return _stakerInfos[sender][stakingIndex];
    }

    /**
     * @dev get current Staker Info.
     */
    function getCurrentStakerInfo(
        address sender
    ) external view returns (StakerInfo memory) {
        // Get user staking index
        uint256 idx = _userStakeIndex[sender];
        return _stakerInfos[sender][idx];
    }

    /**
     * @dev get Staker's index.
     */
    function getUserStakeIndex(address sender) external view returns (uint256) {
        // Get user staking index
        uint256 idx = _userStakeIndex[sender];
        return idx;
    }

    /**
     * @dev get config info based on period
     */
    function getConfig(
        uint256 _period
    ) external view returns (ChefConfig memory) {
        return chefConfig[_period];
    }

    /**
     * @dev calculate booster percent based on NFT holds
     *
     * @param amount: amount of second skin amount of user wallet
     */
    function getBoosterValue(uint256 amount) public view returns (uint256) {
        if (amount > boosterTotal) {
            return _boosters[boosterTotal];
        } else {
            return _boosters[amount];
        }
    }
}
