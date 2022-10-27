//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.9.0;

// custom defined interface
import "./NFTChef.sol";

/**
 * @dev NFT MasterChef educates various NFTChef and lunch them :)
 */
contract NFTMasterChef is Ownable{
    using SafeMath for uint256;    

    // Second Skin NFT
    address public nftstaking;
    // ALTAVA TOKEN (TAVA)
    address public stakedToken;

    // deployed chef total count
    uint256 public total_count;
    // id => deployed chef address
    mapping(uint256 => address) private chefAddress;

    // Deployed new chef Event
    event NewNFTChefContract(
        string id,
        address indexed chef,
        address indexed reward_nft
    );

    // Staked Event
    event Staked(
        address indexed chef,
        address indexed sender, 
        uint256 stake_index,
        uint256 staked_amount, 
        uint256 locked_at, 
        uint256 lock_duration, 
        uint256 unlock_at,
        uint256 nft_balance,
        uint256 booster_percent
    );

    // Unstake Event
    event Unstake(
        address indexed chef,
        address indexed sender, 
        uint256 stake_index,
        uint256 withdraw_amount, 
        uint256 withdraw_at,
        uint256 nft_balance,
        uint256 booster_percent
    );

    // Event whenever updates the "Required Lock Amount"
    event AddedRequiredLockAmount(
        address indexed chef,
        address indexed sender, 
        uint256 period, 
        uint required_amount, 
        uint rewardnft_amount,
        bool is_live
    );
    
    modifier onlySubChef {
        bool isSubChef = false;
        for(uint256 i=0; i < total_count; i++) {
            if (chefAddress[i] == msg.sender) {
                isSubChef = true;
            }
        }
        require(isSubChef, "Role: not sub chef");
        _;
    }

    constructor (
        address _stakedToken,
        address _nftstaking
    ) { 
        require(_nftstaking != address(0x0), "Address should not be zero address");
        require(IERC20(_stakedToken).totalSupply() >= 0);
        nftstaking = _nftstaking;
        stakedToken = _stakedToken;
    }

    /**
     * set nftstaking contract address
     */
    function setNFTStaking(address _nftstaking) external onlyOwner {
        require(_nftstaking != address(0x0), "Address should not be zero address");
        nftstaking = _nftstaking;
    }

    /**
     * @dev deploy the new NFTChef
     * 
     * @param _id `NFTChefs` table unique objectId
     */
    function deploy(
        string memory _id,
        address _rewardNFT,
        uint256[] calldata _booster
    ) external onlyOwner {
        require(_rewardNFT != address(0x0));        
        for(uint256 i=0; i < _booster.length; i++) {
            require(_booster[i] > 0, "Booster value should not be zero");
            require(_booster[i] < 5000, "Booster value should not over 50%");
            if(i > 0) {
                require(_booster[i] >= _booster[i-1], "Booster value should not be increased");
            }
        }

        bytes memory bytecode = type(NFTChef).creationCode;
        // pass constructor argument
        bytecode = abi.encodePacked(
            bytecode,
            abi.encode()
        );
        // This pair address should be unique
        bytes32 salt = keccak256(abi.encodePacked(stakedToken, _rewardNFT, nftstaking));
        address nftChefAddress;

        assembly {
            nftChefAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        
        NFTChef(nftChefAddress).initialize(
            stakedToken,
            _rewardNFT,
            msg.sender,
            nftstaking,
            _booster
        );

        // register address
        chefAddress[total_count] = nftChefAddress;
        total_count = total_count.add(1);

        // emit event
        emit NewNFTChefContract(_id, nftChefAddress, _rewardNFT);
    }

    /**
     * get chef address with id
     */
    function getChefAddress(uint256 id) external view returns(address) {
        require(total_count > id, "Chef: not exist");
        return chefAddress[id];
    }

    /**
     * Emit event from sub chef: Staked
     */
    function emitStakedEventFromSubChef(
        address sender, 
        uint256 stake_index,
        uint256 staked_amount, 
        uint256 locked_at, 
        uint256 lock_duration, 
        uint256 unlock_at,
        uint256 nft_balance,
        uint256 booster_percent
    ) external onlySubChef {
        emit Staked(
            msg.sender,
            sender, 
            stake_index,
            staked_amount, 
            locked_at, 
            lock_duration, 
            unlock_at,
            nft_balance,
            booster_percent
        );
    }

    /**
     * Emit event from sub chef: Unstaked
     */
    function emitUnstakedEventFromSubChef(
        address sender, 
        uint256 stake_index,
        uint256 withdraw_amount, 
        uint256 withdraw_at,
        uint256 nft_balance,
        uint256 booster_percent
    ) external onlySubChef {
        emit Unstake(
            msg.sender,
            sender, 
            stake_index,
            withdraw_amount, 
            withdraw_at,
            nft_balance,
            booster_percent
        );
    }

    /**
     * Emit event from sub chef: AddedRequiredLockAmount
     */
    function emitAddedRequiredLockAmountEventFromSubChef(
        address sender, 
        uint256 period, 
        uint required_amount, 
        uint rewardnft_amount,
        bool is_live
    ) external onlySubChef {
        emit AddedRequiredLockAmount(
            msg.sender,
            sender, 
            period, 
            required_amount, 
            rewardnft_amount,
            is_live
        );
    }
}