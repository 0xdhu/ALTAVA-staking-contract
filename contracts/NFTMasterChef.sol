//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

// custom defined interface
import "./NFTChef.sol";

/**
 * @dev NFT MasterChef educates various NFTChef and lunch them :)
 */
contract NFTMasterChef is Ownable {
    using SafeMath for uint256;

    // Second Skin NFT Staking Contract
    address public nftstaking;
    // ALTAVA TOKEN (TAVA)
    address public stakedToken;

    // deployed chef total count
    uint256 public totalCount;
    // id => deployed chef address
    mapping(uint256 => address) private chefAddress;

    // Deployed new chef Event
    event NewNFTChefContract(
        string id,
        address indexed chef,
        address indexed rewardNFT
    );

    // Staked Event
    event Staked(
        address indexed chef,
        address indexed sender,
        uint256 stakeIndex,
        uint256 stakedAmount,
        uint256 lockedAt,
        uint256 lockDuration,
        uint256 unlockAt,
        uint256 nftBalance,
        uint256 boosterPercent
    );

    // Unstake Event
    event Unstake(
        address indexed chef,
        address indexed sender,
        uint256 stakeIndex,
        uint256 withdrawAmount,
        uint256 withdrawAt,
        uint256 nftBalance,
        uint256 boosterPercent
    );

    // Event whenever updates the "Required Lock Amount"
    event AddedRequiredLockAmount(
        address indexed chef,
        address indexed sender,
        uint256 period,
        uint requiredAmount,
        uint rewardnftAmount,
        bool isLive
    );

    modifier onlySubChef() {
        bool isSubChef = false;
        for (uint256 i = 0; i < totalCount; i++) {
            if (chefAddress[i] == msg.sender) {
                isSubChef = true;
            }
        }
        require(isSubChef, "Role: not sub chef");
        _;
    }

    constructor(address _stakedToken, address _nftstaking) {
        require(_nftstaking != address(0x0), "Cannot be zero address");
        require(IERC20(_stakedToken).totalSupply() >= 0, "Invalid token");
        nftstaking = _nftstaking;
        stakedToken = _stakedToken;
    }

    /**
     * set nftstaking contract address
     */
    function setNFTStaking(address _nftstaking) external onlyOwner {
        require(_nftstaking != address(0x0), "Cannot be zero address");
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
        require(_rewardNFT != address(0x0), "Cannot be zero address");
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

        bytes memory bytecode = type(NFTChef).creationCode;
        // pass constructor argument
        bytecode = abi.encodePacked(bytecode, abi.encode());
        // This pair address should be unique
        bytes32 salt = keccak256(
            abi.encodePacked(stakedToken, _rewardNFT, nftstaking)
        );
        address nftChefAddress;

        assembly {
            nftChefAddress := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }

        NFTChef(nftChefAddress).initialize(
            stakedToken,
            _rewardNFT,
            msg.sender,
            nftstaking,
            _booster
        );

        // register address
        chefAddress[totalCount] = nftChefAddress;
        totalCount = totalCount.add(1);

        // emit event
        emit NewNFTChefContract(_id, nftChefAddress, _rewardNFT);
    }

    /**
     * get chef address with id
     */
    function getChefAddress(uint256 id) external view returns (address) {
        require(totalCount > id, "Chef: not exist");
        return chefAddress[id];
    }

    /**
     * Emit event from sub chef: Staked
     */
    function emitStakedEventFromSubChef(
        address sender,
        uint256 stakeIndex,
        uint256 stakedAmount,
        uint256 lockedAt,
        uint256 lockDuration,
        uint256 unlockAt,
        uint256 nftBalance,
        uint256 boosterPercent
    ) external onlySubChef {
        emit Staked(
            msg.sender,
            sender,
            stakeIndex,
            stakedAmount,
            lockedAt,
            lockDuration,
            unlockAt,
            nftBalance,
            boosterPercent
        );
    }

    /**
     * Emit event from sub chef: Unstaked
     */
    function emitUnstakedEventFromSubChef(
        address sender,
        uint256 stakeIndex,
        uint256 withdrawAmount,
        uint256 withdrawAt,
        uint256 nftBalance,
        uint256 boosterPercent
    ) external onlySubChef {
        emit Unstake(
            msg.sender,
            sender,
            stakeIndex,
            withdrawAmount,
            withdrawAt,
            nftBalance,
            boosterPercent
        );
    }

    /**
     * Emit event from sub chef: AddedRequiredLockAmount
     */
    function emitAddedRequiredLockAmountEventFromSubChef(
        address sender,
        uint256 period,
        uint requiredAmount,
        uint rewardnftAmount,
        bool isLive
    ) external onlySubChef {
        emit AddedRequiredLockAmount(
            msg.sender,
            sender,
            period,
            requiredAmount,
            rewardnftAmount,
            isLive
        );
    }
}
