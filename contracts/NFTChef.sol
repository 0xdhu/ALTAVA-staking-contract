//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/INFTMasterChef.sol";
import "./interfaces/INFTStaking.sol";

/**
 * @dev This NFTChef airdrops yummy third-party NFT to TAVA token stakers.
 */
contract NFTChef is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // The address of the smart chef factory
    address public immutable NFT_MASTER_CHEF_FACTORY;

    // Second Skin NFT Staking Contract
    INFTStaking public nftstaking;

    // TAVA ERC20 token
    IERC20 public stakedToken;
    // NFT token for airdrop
    address public rewardNFT;
    // Whether it is initialized
    bool public isInitialized;

    // User stake info
    struct StakerInfo {
        uint256 lockedAmount;
        uint256 lockDuration;
        uint256 rewardAmount;
        uint256 lockedAt;
        uint256 unlockAt;
        bool unstaked;
    }

    // User's staking info on index
    mapping(address => mapping(uint256 => StakerInfo)) private stakerInfos;
    // How many staker participated on staking
    mapping(address => uint256) private userStakeIndex;

    struct ChefConfig {
        uint256 requiredLockAmount;
        uint256 rewardNFTAmount;
        bool isLive;
    }

    // Required TAVA amount based on Locked period options
    // Period (days) => ChefConfig
    mapping(uint256 => ChefConfig) public chefConfig;

    // Booster values
    // holding amount => booster percent
    // Percent real value: need to divide by 100. ex: 152 means 1.52%
    // index => value
    mapping(uint256 => uint256) private boosters;
    // booster total number
    uint256 public booster_total;
    // Booster denominator
    uint256 public DENOMINATOR = 10000;

    // Constructor (initialize some configurations)
    constructor() {
        NFT_MASTER_CHEF_FACTORY = msg.sender;
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
        address _rewardNFT,
        address _newOwner,
        address _nftstaking,
        uint256[] calldata _booster
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == NFT_MASTER_CHEF_FACTORY, "Not factory");

        // Make this contract initialized
        isInitialized = true;

        stakedToken = IERC20(_stakedToken);
        rewardNFT = _rewardNFT;
        nftstaking = INFTStaking(_nftstaking);

        // If didnot stake any amount of NFT, booster is just zero
        boosters[0] = 0;
        for (uint256 i = 0; i < _booster.length; i++) {
            boosters[i + 1] = _booster[i];
        }
        booster_total = _booster.length;

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_newOwner);
    }

    /**
     * @dev calculate booster percent based on NFT holds
     *
     * @param amount: amount of second skin amount of user wallet
     */
    function getBoosterValue(uint256 amount) public view returns (uint256) {
        if (amount > booster_total) {
            return boosters[booster_total];
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

    /**
     * @dev set booster value on index
     */
    function setBoosterValue(uint256 idx, uint256 value) external onlyOwner {
        require(idx <= booster_total + 1, "Out of index");
        require(idx > 0, "Index should not be zero");
        require(value > 0, "Booster value should not be zero");
        require(value < 5000, "Booster value should not be over than 50%");
        require(boosters[idx] != value, "Amount in use");
        boosters[idx] = value;
        if (idx == booster_total + 1) booster_total = booster_total.add(1);

        if (idx > 1 && idx <= booster_total) {
            require(
                boosters[idx] >= boosters[idx - 1],
                "Booster value should be increased"
            );
            if (idx < booster_total) {
                require(
                    boosters[idx + 1] >= boosters[idx],
                    "Booster value should be increased"
                );
            }
        } else if (idx == 1 && booster_total > 1) {
            require(
                boosters[idx + 1] >= boosters[idx],
                "Booster value should be increased"
            );
        }
    }

    /**
     * @dev Admin should be able to set required lock amount based on lock period
     * @param _lockPeriod: Lock duration
     * @param _requiredAmount: Required lock amount to participate on staking period related option.
     * @param _rewardNFTAmount: Reward amount of thirdparty NFT.
     */
    function setRequiredLockAmount(
        uint256 _lockPeriod,
        uint256 _requiredAmount,
        uint256 _rewardNFTAmount,
        bool _isLive
    ) external onlyOwner {
        // require(_lockPeriod >= 3600, "Lock period: at least 1 day");
        if (_isLive == false) {
            chefConfig[_lockPeriod].isLive = false;
        } else {
            chefConfig[_lockPeriod] = ChefConfig(
                _requiredAmount,
                _rewardNFTAmount,
                _isLive
            );
        }

        INFTMasterChef(NFT_MASTER_CHEF_FACTORY)
            .emitAddedRequiredLockAmountEventFromSubChef(
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
        // Check `msg.sender`
        require(_sender != address(0x0), "Invalid sender");

        ChefConfig memory _chefConfig = chefConfig[_lockPeriod];
        require(_chefConfig.isLive == true, "This option is not in live");

        uint256 requiredAmount = _chefConfig.requiredLockAmount;
        require(requiredAmount > 0, "This option doesnot exist");

        // Get user staking index
        uint256 idx = userStakeIndex[_sender];
        // Get object of user info
        StakerInfo storage _userInfo = stakerInfos[_sender][idx];
        require(
            _userInfo.unstaked == false,
            "This locked staking has been already unstaked"
        );

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
            "Expired. Please withdraw previous one and renew it"
        );
        nftstaking.update_info(_sender);

        // Balance of secondskin NFT
        uint256 nft_balance = nftstaking.getStakedNFTCount(_sender);
        // get booster percent
        uint256 booster_value = getBoosterValue(nft_balance);
        // decrease required amount
        uint256 _decreaseAmount = requiredAmount.mul(booster_value).div(
            DENOMINATOR
        );
        uint256 _requiredAmount = requiredAmount - _decreaseAmount;

        // current locked amount
        uint256 currentBalance = _userInfo.lockedAmount;
        // If required amount is bigger than current balance, need to ask more staking.
        // If not, just need to extend reward amount
        if (_requiredAmount > currentBalance) {
            // the required amount to extend locked duration
            uint256 transferAmount = _requiredAmount.sub(currentBalance);
            // NOTE: approve token to extend allowance
            // Check token balance of sender
            require(
                stakedToken.balanceOf(_sender) >= transferAmount,
                "Token: Insufficient balance"
            );
            // transfer from sender to address(this)
            stakedToken.transferFrom(_sender, address(this), transferAmount);

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
        _userInfo.rewardAmount = _rewardNFTAmount;
        _userInfo.lockDuration = _lockPeriod;
        _userInfo.unlockAt = _unlock_at;

        INFTMasterChef(NFT_MASTER_CHEF_FACTORY).emitStakedEventFromSubChef(
            _sender,
            idx,
            _userInfo.lockedAmount,
            _userInfo.lockedAt,
            _userInfo.lockDuration,
            _userInfo.unlockAt,
            nft_balance,
            booster_value
        );
    }

    /**
     * @dev unstake locked tokens after lock duration manually
     */
    function unstake() external nonReentrant {
        address _sender = msg.sender;

        // Check `msg.sender`
        require(_sender != address(0x0), "Invalid sender");
        // Get user staking index
        uint256 idx = userStakeIndex[_sender];
        // Get object of user info
        StakerInfo storage _userInfo = stakerInfos[_sender][idx];

        require(_userInfo.lockedAmount > 0, "Your position not exist");
        require(_userInfo.unlockAt < block.timestamp, "Not able to withdraw");

        // Neet to get required amount basis current secondskin NFT amount.
        ChefConfig memory _chefConfig = chefConfig[_userInfo.lockDuration];
        uint256 requiredAmount = _chefConfig.requiredLockAmount;
        // Balance of NFT
        uint256 nft_balance = nftstaking.getStakedNFTCount(_sender);
        // get booster percent
        uint256 booster_value = getBoosterValue(nft_balance);
        uint256 _decreaseAmount = requiredAmount.mul(booster_value).div(
            DENOMINATOR
        );
        uint256 _requiredAmount = requiredAmount.sub(_decreaseAmount);

        // Check pool balance
        uint unstakable_amount = _userInfo.lockedAmount;
        require(
            stakedToken.balanceOf(address(this)) >= unstakable_amount,
            "Token: Insufficient pool"
        );
        require(
            _userInfo.unstaked == false,
            "This locked staking has been already unstaked"
        );
        // Set flag unstaked
        _userInfo.unstaked = true;

        // If require amount is bigger than current locked amount, which means user transferred NFT
        // that was used as booster
        if (_requiredAmount > unstakable_amount) {
            uint256 _panaltyAmount = _requiredAmount.sub(unstakable_amount);
            uint256 withdrawAmount = unstakable_amount.sub(_panaltyAmount);
            // If user has no NFT that staked before atm, need to pay panalty
            stakedToken.transfer(owner(), _panaltyAmount);
            // transfer from pool to user
            stakedToken.transfer(_sender, withdrawAmount);
        } else {
            // transfer from pool to user
            stakedToken.transfer(_sender, unstakable_amount);
        }

        // increase index
        userStakeIndex[_sender] = idx + 1;

        INFTMasterChef(NFT_MASTER_CHEF_FACTORY).emitUnstakedEventFromSubChef(
            _sender,
            idx,
            unstakable_amount,
            block.timestamp,
            nft_balance,
            booster_value
        );
    }

    /**
     * @dev get Panalty amount
     */
    function getPanaltyAmount(address sender) public view returns (uint256) {
        // Get user staking index
        uint256 idx = userStakeIndex[sender];
        StakerInfo memory _userInfo = stakerInfos[sender][idx];
        // Neet to get required amount basis current secondskin NFT amount.
        ChefConfig memory _chefConfig = chefConfig[_userInfo.lockDuration];
        uint256 requiredAmount = _chefConfig.requiredLockAmount;
        // Balance of NFT
        uint256 nft_balance = nftstaking.getStakedNFTCount(sender);
        // get booster percent
        uint256 booster_value = getBoosterValue(nft_balance);
        uint256 _decreaseAmount = requiredAmount.mul(booster_value).div(
            DENOMINATOR
        );
        uint256 _requiredAmount = requiredAmount - _decreaseAmount;
        uint unstakable_amount = _userInfo.lockedAmount;
        if (_requiredAmount > unstakable_amount) {
            uint256 _panaltyAmount = _requiredAmount.sub(unstakable_amount);
            return _panaltyAmount;
        }
        return 0;
    }

    /**
     * @dev get Staker Info.
     */
    function getStakerInfo(address sender, uint256 stakingIndex)
        public
        view
        returns (StakerInfo memory)
    {
        return stakerInfos[sender][stakingIndex];
    }

    /**
     * @dev get current Staker Info.
     */
    function getCurrentStakerInfo(address sender)
        public
        view
        returns (StakerInfo memory)
    {
        // Get user staking index
        uint256 idx = userStakeIndex[sender];
        return stakerInfos[sender][idx];
    }

    /**
     * @dev get Staker's index.
     */
    function getUserStakeIndex(address sender) public view returns (uint256) {
        // Get user staking index
        uint256 idx = userStakeIndex[sender];
        return idx;
    }

    /**
     * @dev get config info based on period
     */
    function getConfig(uint256 _period)
        public
        view
        returns (ChefConfig memory)
    {
        return chefConfig[_period];
    }
}
