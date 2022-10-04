//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.9.0;

// Openzeppelin libraries
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

// import "hardhat/console.sol";

/**
 * In ERC20 staking, to get more rewarded, you need to use booster.
 * Booster option will be active only when you stake your SecondSkin NFT
 */
contract SecondSkinNFTStaking is Ownable, ReentrancyGuard, ERC721Holder{
    IERC721 public secondskinnft;

    struct LockedInfo {
        bool isLocked;
        // Last time of details update for this User
        uint256 timeOfLastUpdate;
    }

    // sender => tokenid => locked Info
    mapping(address => mapping(uint => LockedInfo)) public isNFTLocked;
    // sender => tokenid => locked or not
    mapping(address => uint) public lockCount;

    // Locked event
    event SecondSkinNFTLocked(
        address indexed sender, 
        address indexed nftAddress, 
        uint tokenId, 
        uint256 timeOfLastUpdate
    );

    // Unlocked event
    event SecondSkinNFTUnlocked(
        address indexed sender, 
        address indexed nftAddress, 
        uint tokenId, 
        uint256 timeOfLastUpdate
    );

    constructor (IERC721 _secondskinnft) {
        secondskinnft = _secondskinnft;
    }


    // Middleware to check if msg.sender is token owner
    modifier onlyTokenOwner(uint256 tokenId) {
        address tokenOwner = secondskinnft.ownerOf(tokenId);

        require(
            tokenOwner == msg.sender,
            "Token Owner: you are not a token owner"
        );
        _;
    }

    /**
     * @dev Stake Second skin NFT
     */
    function stake(
        uint _tokenId
    ) external
      onlyTokenOwner(_tokenId)
    {
        require(isNFTLocked[msg.sender][_tokenId].isLocked == false, "Stake: you already staked");

        secondskinnft.transferFrom(msg.sender, address(this), _tokenId);

        uint timeOfLastUpdate = block.timestamp;
        isNFTLocked[msg.sender][_tokenId].isLocked = true;
        isNFTLocked[msg.sender][_tokenId].timeOfLastUpdate = timeOfLastUpdate;

        uint total = lockCount[msg.sender];
        lockCount[msg.sender] = total + 1;

        emit SecondSkinNFTLocked(msg.sender, address(secondskinnft), _tokenId, timeOfLastUpdate);
    }

    /**
     * @dev Unstake Second skin NFT
     */
    function unstake(
        uint _tokenId
    ) external 
      nonReentrant
    {
        require(isNFTLocked[msg.sender][_tokenId].isLocked, "UnStake: you have not staked this NFT");

        uint total = lockCount[msg.sender];
        require(total >= 1, "UnStake: insufficient balance");

        uint timeOfLastUpdate = block.timestamp;

        lockCount[msg.sender] = total - 1;
        isNFTLocked[msg.sender][_tokenId].isLocked = false;
        isNFTLocked[msg.sender][_tokenId].timeOfLastUpdate = timeOfLastUpdate;


        secondskinnft.transferFrom(address(this), msg.sender, _tokenId);
        
        emit SecondSkinNFTUnlocked(msg.sender, address(secondskinnft), _tokenId, timeOfLastUpdate);
    }

    /**
     * @dev to calculate booster, we need to get nft number locked by user
     */
    function getUserLockedNFTCounter() external view returns(uint) {
        return lockCount[msg.sender];
    }
}