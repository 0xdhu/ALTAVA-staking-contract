//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

// Openzeppelin libraries
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/INFTStaking.sol";
import "./interfaces/IMasterChef.sol";

/**
 * @dev Stake TAVA with locked staking and distribute third-party token
 */
contract SmartChef is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Metadata;

    // The address of the smart chef factory
    address public immutable masterSmartChefFactory;

    // stakedToken
    IERC20Metadata public stakedToken;
    // rewardToken
    IERC20Metadata public rewardToken;
    // Second Skin NFT Staking Contract
    INFTStaking public nftstaking;

    // admin withdrawable
    bool private adminWithdrawable = true;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;
    /**
     *  @dev Structs to store user staking data.
     */
    struct UserInfo {
        uint256 lockedAmount;
        uint256 lockStartTime; // lock start time.
        uint256 lockEndTime; // lock end time.
        uint256 lastUserActionTime; // keep track of the last user action time.
        bool locked; //lock status.
        uint256 rewards;
        uint256 rewardDebt;
        uint256 boosterValue; // current booster value
    }

    // admin
    address public admin;
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
    // The pool limit (0 if none)
    uint256 public poolLimitPerUser;
    // Whether a limit is set for users
    bool public userLimit;
    // Block numbers available for user limit (after start block)
    uint256 public numberBlocksForUserLimit;
    // third-party rewardToken created per block.
    uint256 public rewardPerBlock;

    // Booster values
    // holding amount => booster percent
    // Percent real value: need to divide by 100. ex: 152 means 1.52%
    // index => value
    mapping(uint256 => uint256) private boosters;
    // booster total number
    uint256 public boosterTotal;
    // Booster denominator
    uint256 public constant DENOMINATOR = 10000;

    uint256 public constant MIN_LOCK_DURATION = 1 weeks;
    uint256 public constant MAX_LOCK_DURATION = 1000 days;
    uint256 public constant MIN_DEPOSIT_AMOUNT = 0.00001 ether;

    event NewPoolLimit(uint256 poolLimitPerUser);

    constructor() {
        masterSmartChefFactory = msg.sender;
    }

    /*
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _bonusEndBlock: end block
     * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
     * @param _numberBlocksForUserLimit: block numbers available for user limit (after start block)
     * @param _admin: admin address to withdraw automatically
     * @param _newOwner: need to set new owner because now factory is owner
     */
    function initialize(
        IERC20Metadata _stakedToken,
        IERC20Metadata _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _poolLimitPerUser,
        uint256 _numberBlocksForUserLimit,
        address _admin,
        address _newOwner,
        address _nftstaking
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == masterSmartChefFactory, "Not factory");

        // Make this contract initialized
        isInitialized = true;

        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        if (_poolLimitPerUser > 0) {
            userLimit = true;
            poolLimitPerUser = _poolLimitPerUser;
            numberBlocksForUserLimit = _numberBlocksForUserLimit;
        }

        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be less than 30");

        precisionFactor = uint256(10**(uint256(30) - decimalsRewardToken));

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;
        // admin to do automatically withdraw
        admin = _admin;
        // nft staking
        nftstaking = INFTStaking(_nftstaking);

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_newOwner);
    }

    /**
     * @dev calculate booster percent based on NFT holds
     *
     * @param amount: amount of second skin amount of user wallet
     */
    function getBoosterValue(uint256 amount) public view returns (uint256) {
        if (amount > boosterTotal) {
            return boosters[boosterTotal];
        } else {
            return boosters[amount];
        }
    }

    /**
     * @dev get booster percent of user wallet.
     */
    function getStakerBoosterValue(address sender)
        public
        view
        returns (uint256)
    {
        uint256 amount = nftstaking.getStakedNFTCount(sender);
        return getBoosterValue(amount);
    }

    function setBoosterArray(uint256[] calldata _booster) external onlyOwner {
        for (uint256 i = 0; i < _booster.length; i++) {
            require(_booster[i] > 0, "Booster value should not be zero");
            require(_booster[i] < 5000, "Booster rate: overflow 50%");
            if (i > 0) {
                require(
                    _booster[i] >= _booster[i - 1],
                    "Booster value: invalid"
                );
            }
        }
        // If didnot stake any amount of NFT, booster is just zero
        boosters[0] = 0;
        for (uint256 i = 0; i < _booster.length; i++) {
            boosters[i + 1] = _booster[i];
        }
        boosterTotal = _booster.length;
    }

    /**
     * @dev set booster value on index
     */
    function setBoosterValue(uint256 idx, uint256 value) public onlyOwner {
        require(idx <= boosterTotal + 1, "Out of index");
        require(idx > 0, "Index should not be zero");
        require(value > 0, "Booster value should not be zero");
        require(value < 5000, "Booster rate: overflow 50%");
        require(boosters[idx] != value, "Amount in use");
        boosters[idx] = value;
        if (idx == boosterTotal + 1) boosterTotal = boosterTotal.add(1);

        if (idx > 1 && idx <= boosterTotal) {
            require(
                boosters[idx] >= boosters[idx - 1],
                "Booster value: invalid"
            );
            if (idx < boosterTotal) {
                require(
                    boosters[idx + 1] >= boosters[idx],
                    "Booster value: invalid"
                );
            }
        } else if (idx == 1 && boosterTotal > 1) {
            require(
                boosters[idx + 1] >= boosters[idx],
                "Booster value: invalid"
            );
        }
    }

    // modifier to check admin
    modifier onlyAdmin() {
        require(admin == msg.sender, "Invalid admin");
        _;
    }

    /**
     * @notice Checks if the msg.sender is either the cake owner address or the operator address.
     */
    modifier onlyOperatorOrStaker(address _user) {
        require(
            msg.sender == _user || msg.sender == admin,
            "Not operator or staker"
        );
        _;
    }

    /**
     * @dev admin would withdraw the locked token to user, so that withdraw would be done automatically in user side.
     */
    function setAdminWithdrawable(bool flag) external onlyOwner {
        require(adminWithdrawable != flag, "Same setting");
        adminWithdrawable = flag;
    }

    /*
     * @notice Stake TAVA token to get rewarded with third-party nft.
     * @param _amount: amount to lock
     * @param _lockDuration: duration to lock
     */
    function stake(uint256 _amount, uint256 _lockDuration)
        external
        _realAddress(msg.sender)
        _hasAllowance(msg.sender, _amount)
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        require(_amount > 0 || _lockDuration > 0, "Nothing to deposit");
        return (_stake(_amount, _lockDuration, msg.sender));
    }

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
            require(user.locked == false, "Unlock previous one");

            userLimit = hasUserLimit();
            require(
                !userLimit || (currentLockedAmount <= poolLimitPerUser),
                "Stake: Amount above limit"
            );
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

        _updatePool();

        if (user.lockedAmount > 0) {
            uint256 pending = ((user.lockedAmount * accTokenPerShare) /
                precisionFactor).sub(user.rewardDebt);
            if (pending > 0) {
                user.rewards = user.rewards.add(pending);
            }
        }

        if (_amount > 0) {
            user.lockedAmount = user.lockedAmount.add(_amount);
            stakedToken.safeTransferFrom(
                address(_user),
                address(this),
                _amount
            );
        }

        user.rewardDebt =
            (user.lockedAmount * accTokenPerShare) /
            precisionFactor;
        user.lastUserActionTime = block.timestamp;
        user.lockEndTime = user.lockStartTime.add(_lockDuration);
        user.locked = true;
        user.boosterValue = getStakerBoosterValue(_user);

        IMasterChef(masterSmartChefFactory).emitStakedEventFromSubChef(
            _user,
            _amount,
            user.lockStartTime,
            user.lockEndTime,
            block.timestamp,
            user.rewards,
            user.rewardDebt,
            user.boosterValue
        );
        return true;
    }

    /**
     * @notice Unlock staked tokens (Unlock)
     * @dev user side withdraw manually
     */
    function unlock(address _user)
        external
        _realAddress(_user)
        onlyOperatorOrStaker(_user)
        nonReentrant
        returns (bool)
    {
        UserInfo storage user = userInfo[_user];
        uint256 _amount = user.lockedAmount;
        require(_amount > 0, "Empty to unlock");
        require(user.locked == true, "Already unlocked");
        require(user.lockEndTime < block.timestamp, "Still in locked");

        _updatePool();

        if (_amount > 0) {
            uint256 pending = ((_amount * accTokenPerShare) / precisionFactor)
                .sub(user.rewardDebt);
            if (pending > 0) {
                user.rewards = user.rewards.add(pending);
            }
        }

        // set zero
        user.lockedAmount = 0;
        user.locked = false;
        user.lastUserActionTime = block.timestamp;
        user.boosterValue = getStakerBoosterValue(_user);
        user.rewardDebt = 0;

        // unlock staked token
        stakedToken.safeTransfer(address(_user), _amount);

        uint256 rewardAmount = user.rewards;
        // Here, should be check pool balance as well as if admin is able to harvest users reward to users.
        if (adminWithdrawable == false && rewardAmount > 0) {
            require(
                rewardToken.balanceOf(address(this)) >= rewardAmount,
                "Insufficient pool"
            );
            user.rewards = 0;

            rewardToken.safeTransfer(address(_user), rewardAmount);
        }

        IMasterChef(masterSmartChefFactory).emitUnstakedEventFromSubChef(
            _user,
            user.lastUserActionTime,
            user.rewards,
            user.boosterValue
        );

        return true;
    }

    /**
     * @dev to calculate total rewards based on user rewards
     */
    function calculate(address from) external view returns (uint256) {
        return _calculate(from);
    }

    function _calculate(address from) private view returns (uint256) {
        UserInfo memory user = userInfo[from];
        // Calculate total reward
        uint256 pending = ((user.lockedAmount * accTokenPerShare) /
            precisionFactor).sub(user.rewardDebt);
        return user.rewards.add(pending);
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
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

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to - _from;
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock - _from;
        }
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }

    modifier _realAddress(address addr) {
        require(addr != address(0), "Zero address");
        _;
    }

    modifier _hasAllowance(address allower, uint256 amount) {
        // Make sure the allower has provided the right allowance.
        IERC20Metadata erc20Interface = IERC20Metadata(stakedToken);
        uint256 ourAllowance = erc20Interface.allowance(allower, address(this));
        require(amount <= ourAllowance, "Not enough allowance");
        _;
    }

    /*
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _userLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(bool _userLimit, uint256 _poolLimitPerUser)
        external
        onlyOwner
    {
        require(userLimit, "Must be set");
        if (_userLimit) {
            require(
                _poolLimitPerUser > poolLimitPerUser,
                "New limit must be higher"
            );
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            userLimit = _userLimit;
            poolLimitPerUser = 0;
        }
        emit NewPoolLimit(poolLimitPerUser);
    }

    /*
     * @notice Return user limit is set or zero.
     */
    function hasUserLimit() public view returns (bool) {
        if (
            !userLimit ||
            (block.number >= (startBlock + numberBlocksForUserLimit))
        ) {
            return false;
        }

        return true;
    }
}
