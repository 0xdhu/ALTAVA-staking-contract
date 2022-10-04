//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.9.0;

// Openzeppelin libraries
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// development mode
// import "hardhat/console.sol";

/**
 * @dev This NFTChef airdrops yummy third-party NFT to TAVA token stakers.
 */
contract NFTChef is Ownable, ReentrancyGuard{
    using SafeMath for uint256;

    // The address of the smart chef factory
    address public immutable NFT_MASTER_CHEF_FACTORY;

    // TAVA ERC20 token
    IERC20 public stakedToken;
    // NFT token for airdrop
    address public nftForAirdrop;

    // admin withdrawable
    bool adminWithdrawable = true;
    // admin for withdrawable automatically
    address private admin;
    // Whether it is initialized
    bool public isInitialized;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 lockedAmount;
        uint256 lockDuration;        
        uint256 airdropAmount;
        uint256 lockedAt;
        uint256 unlockAt;
    }

    // Required TAVA amount based on Locked period options
    // Period (days) => Required amount
    mapping(uint256 => uint256) public requiredLockAmounts;
    // Period (days) => Airdrop amount
    mapping(uint256 => uint256) public airdropAmounts;

    // User info
    mapping(address => UserInfo) private userInfos;

    // Staked Event
    event Staked(
        address indexed sender, 
        uint256 staked_amount, 
        uint256 locked_at, 
        uint256 lock_duration, 
        uint256 unlock_at
    );
    // Withdraw Event
    event Withdraw(
        address indexed sender, 
        uint256 withdraw_amount, 
        uint256 withdraw_at
    );
    // Event whenever updates the "Required Lock Amount"
    event AddedRequiredLockAmount(address indexed sender, uint256 period, uint required_amount);

    // Constructor (initialize some configurations)
    constructor () {
        NFT_MASTER_CHEF_FACTORY = msg.sender;
    }

    /*
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _nftForAidrop: reward token address (airdrop NFT)
     * @param _admin: admin address to withdraw automatically
     * @param _newOwner: need to set new owner because now factory is owner
     */
    function initialize(
        address _stakedToken,
        address _nftForAidrop,
        address _admin,
        address _newOwner
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == NFT_MASTER_CHEF_FACTORY, "Not factory");

        // Make this contract initialized
        isInitialized = true;

        stakedToken = IERC20(_stakedToken);
        nftForAirdrop = _nftForAidrop;
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

    /**
     * @dev admin would withdraw the locked token to user, so that withdraw would be done automatically in user side.
     */
    function setAdmin(address _admin) external onlyOwner {
        require(admin != _admin, "Same setting");
        admin = _admin;
    }    

    /**
     * @dev Admin should be able to set required lock amount based on lock period
     * @param _lockPeriod: Lock duration
     * @param _requiredAmount: Required lock amount to participate on staking period related option.
     */
    function setRequiredLockAmount(
        uint256 _lockPeriod,
        uint256 _requiredAmount,
        uint256 _airdropAmount
    ) external onlyOwner {
        require(requiredLockAmounts[_lockPeriod] == _requiredAmount, "This value is in use");
        require(airdropAmounts[_lockPeriod] == _airdropAmount, "This value is in use");

        requiredLockAmounts[_lockPeriod] = _requiredAmount;
        airdropAmounts[_lockPeriod] = _airdropAmount;

        emit AddedRequiredLockAmount(msg.sender, _lockPeriod, _requiredAmount);
    }

    /**
     * @notice this is ERC20 locked staking to get third-party NFT airdrop
     * @dev stake function with ERC20 token. this has also extend days function as well.
     * 
     * @param _lockPeriod: locked options. (i.e. 30days, 60days, 90days)
     */
    function stake(
        uint256 _lockPeriod
    ) external nonReentrant {
        // Check `msg.sender`
        require(msg.sender != address(0x0), "Invalid sender");

        uint256 _requiredAmount = requiredLockAmounts[_lockPeriod];
        require(_requiredAmount > 0, "This option doesnot exist");

        // Get object of user info
        UserInfo storage _userInfo = userInfos[msg.sender];
        require(_userInfo.lockDuration < _lockPeriod, "Stake: Invalid period");
        
        // check airdrop amount
        uint256 _airdropAmount = airdropAmounts[_lockPeriod];
        require(_airdropAmount > _userInfo.lockDuration, "Invalid airdrop amount");

        // check if staking is expired and renew it or check if staking not exist
        require(
            _userInfo.unlockAt >= block.timestamp ||
            _userInfo.lockedAmount == 0, 
            "Expired. Please withdraw previous one and renew it"
        );

        // current locked amount
        uint256 currentBalance = _userInfo.lockedAmount;
        if(_requiredAmount >= currentBalance) {
            // the required amount to extend locked duration
            uint256 transferAmount = _requiredAmount.sub(currentBalance);
            // NOTE: approve token to extend allowance
            // Check token balance of sender
            require(stakedToken.balanceOf(msg.sender) >= transferAmount, "Token: Insufficient balance");
            // transfer from sender to address(this)
            stakedToken.transferFrom(msg.sender, address(this), transferAmount);

            // Update user Info
            _userInfo.lockedAmount = _requiredAmount;
        }


        // If this stake is first time for this sender, we need to set `lockedAt` timestamp
        // If this stake is for extend days, just ignore it.
        if (_userInfo.lockDuration == 0) {
            _userInfo.lockedAt = block.timestamp;
        }

        uint256 _unlock_at = _userInfo.lockedAt.add(_lockPeriod);

        // Update userinfo to up-to-date info
        _userInfo.airdropAmount = _airdropAmount;
        _userInfo.lockDuration = _lockPeriod;
        _userInfo.unlockAt = _unlock_at;

        emit Staked(
            msg.sender, 
            _userInfo.lockedAmount, 
            _userInfo.lockedAt,
            _lockPeriod,
            _unlock_at
        );
    }

    // user side withdraw manually
    function withdraw() external {
        require(adminWithdrawable == false, "withdraw would be done automatically");
        _withdraw(msg.sender);
    }

    // admin side withdraw automatically
    function adminWithdraw(address sender) external onlyAdmin {
        require(adminWithdrawable, "withdraw cannot be done automatically");
        _withdraw(sender);
    }

    /**
     * @dev withdraw locked tokens after lock duration.
     */
    function _withdraw(address sender) private nonReentrant {
        // Check `msg.sender`
        require(sender != address(0x0), "Invalid sender");
        // Get object of user info
        UserInfo storage _userInfo = userInfos[sender];
        require(_userInfo.lockedAmount > 0, "Your position not exist");
        require(_userInfo.unlockAt < block.timestamp, "Not able to withdraw");

        uint withdrawal_amount = _userInfo.lockedAmount;
        require(stakedToken.balanceOf(address(this)) >= withdrawal_amount, "Token: Insufficient pool");
        // Reset user info
        _userInfo.lockedAmount=0;
        _userInfo.lockDuration=0;
        _userInfo.airdropAmount=0;

        // transfer from pool to user
        stakedToken.transfer(sender, withdrawal_amount);

        emit Withdraw(sender, withdrawal_amount, block.timestamp);
    }

    /**
     * @dev get info of sender.
     */
    function getUserInfo(address sender) external view returns(UserInfo memory) {
        return userInfos[sender];
    }
}