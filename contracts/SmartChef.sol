//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.9.0;

// Openzeppelin libraries
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// import "hardhat/console.sol";

/**
 * @dev Stake TAVA with locked staking and distribute third-party token
 */
contract SmartChef is Ownable, ReentrancyGuard, Pausable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20Metadata;

    // The address of the smart chef factory
    address public immutable MASTER_SMART_CHEF_FACTORY;

    // stakedToken
    IERC20Metadata public stakedToken;
    // rewardToken
    IERC20Metadata public rewardToken;

    // admin withdrawable
    bool adminWithdrawable = true;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;
    /**
     *  @dev Structs to store user staking data.
     */
    struct UserInfo {
        uint256 depositAmount;
        uint256 depositTime;
        uint256 endTime;
        uint256 rewards;
        uint256 rewardDebt;
        bool paid;
    }

    // admin
    address public admin;
    // The precision factor
    uint256 public PRECISION_FACTOR;
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


    event Stake(address indexed user, uint256 amount);
    event NewPoolLimit(uint256 poolLimitPerUser);
    event Withdraw(address indexed user, uint256 stakedAmount, uint256 totalReward);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
    ) {
        MASTER_SMART_CHEF_FACTORY = msg.sender;
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
        address _newOwner
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == MASTER_SMART_CHEF_FACTORY, "Not factory");

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

        PRECISION_FACTOR = uint256(10**(uint256(30) - decimalsRewardToken));

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;
        // admin to do automatically withdraw
        admin = _admin;
        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_newOwner);
    }

    // modifier to check admin
    modifier onlyAdmin {
        require(admin == msg.sender, "Invalid admin");
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
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to stake
     */
    function stake(uint256 _amount)
        external
        _realAddress(msg.sender)
        _hasAllowance(msg.sender, _amount)
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        require(_amount > 0, "Can't stake 0 amount");
        return (_stake(_amount));
    }

    function _stake(uint256 _amount) private returns (bool) {
        UserInfo storage user = userInfo[msg.sender];

        userLimit = hasUserLimit(); 
        require(!userLimit || ((_amount + user.depositAmount) <= poolLimitPerUser), "Stake: Amount above limit");
        _updatePool();

        if (user.depositAmount > 0) {
            uint256 pending = ((user.depositAmount * accTokenPerShare) / PRECISION_FACTOR).sub(user.rewardDebt);
            if (pending > 0) {
                user.rewards = user.rewards.add(pending);
            }
        }

        if (_amount > 0) {
            user.depositAmount = user.depositAmount + _amount;
            stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        }

        user.rewardDebt = (user.depositAmount * accTokenPerShare) / PRECISION_FACTOR;
        
        emit Stake(msg.sender, _amount);
        return true;
    }

    /**
     * @notice Withdraw staked tokens
     * @dev user side withdraw manually
     */
    function withdraw() external _realAddress(msg.sender) nonReentrant {
        require(adminWithdrawable == false, "withdraw would be done automatically");
        _withdraw(msg.sender);
    }

    /**
     * @notice Withdraw staked tokens
     * @dev admin will transfer collected reward tokens
     */
    function adminWithdraw(address sender) external _realAddress(msg.sender) nonReentrant onlyAdmin {
        require(adminWithdrawable, "withdraw cannot be done automatically");
        _withdraw(sender);
    }

    function _withdraw(address from) private returns (bool) {
        uint256 _amount = userInfo[from].depositAmount;
        require(_amount > 0, "Empty to withdraw");

        _updatePool();

        UserInfo storage user = userInfo[from];
        // Calculate total reward
        uint256 totalReward = _calculate(from);

        // set zero
        user.depositAmount = user.depositAmount - _amount;
        user.rewards = 0;
        user.rewardDebt = 0;

        // withdraw staked token
        stakedToken.safeTransfer(address(from), _amount);

        // Here, should be check pool balance as well as if admin withdraw option has been enabled or not
        if (adminWithdrawable == false) {
            if (totalReward > 0) {
                require(rewardToken.balanceOf(address(this)) >= totalReward, "Insufficient pool");
                rewardToken.safeTransfer(address(from), totalReward);
            }
        }

        emit Withdraw(from, _amount, totalReward);
        return true;
    }


    /**
     * @dev to calculate total rewards based on user rewards
     */
    function calculate(address from) external view returns (uint256) {
        return _calculate(from);
    }

    function _calculate(address from)
        private
        view
        returns (uint256)
    {        
        UserInfo memory user = userInfo[from];
        // Calculate total reward
        uint256 pending = (user.depositAmount * accTokenPerShare) / PRECISION_FACTOR - user.rewardDebt;
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
        uint256 cakeReward = multiplier * rewardPerBlock;
        accTokenPerShare = accTokenPerShare + (cakeReward * PRECISION_FACTOR) / stakedTokenSupply;
        lastRewardBlock = block.number;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to - _from;
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock - _from;
        }
    }
    
    function emergencyWithdraw()
        external
        _realAddress(msg.sender)
        nonReentrant
    {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.depositAmount;
        user.depositAmount = 0;
        user.rewardDebt = 0;

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, user.depositAmount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }

    function _payMe(address payer, uint256 amount) private returns (bool) {
        return _payTo(payer, address(this), amount);
    }

    function _payTo(
        address allower,
        address receiver,
        uint256 amount
    ) private _hasAllowance(allower, amount) returns (bool) {
        IERC20Metadata ERC20Interface = IERC20Metadata(stakedToken);
        ERC20Interface.safeTransferFrom(allower, receiver, amount);
        return true;
    }

    function _payDirect(address to, uint256 amount) private returns (bool) {
        IERC20Metadata ERC20Interface = IERC20Metadata(stakedToken);
        ERC20Interface.safeTransfer(to, amount);
        return true;
    }

    modifier _realAddress(address addr) {
        require(addr != address(0), "Zero address");
        _;
    }

    modifier _hasAllowance(address allower, uint256 amount) {
        // Make sure the allower has provided the right allowance.
        IERC20Metadata ERC20Interface = IERC20Metadata(stakedToken);
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        _;
    }

    /*
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _userLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(bool _userLimit, uint256 _poolLimitPerUser) external onlyOwner {
        require(userLimit, "Must be set");
        if (_userLimit) {
            require(_poolLimitPerUser > poolLimitPerUser, "New limit must be higher");
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
        if (!userLimit || (block.number >= (startBlock + numberBlocksForUserLimit))) {
            return false;
        }

        return true;
    }
}