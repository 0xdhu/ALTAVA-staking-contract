//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

// custom defined interface
import "./NFTChef.sol";
import "./interfaces/INFTMasterChef.sol";

/**
 * @dev NFT MasterChef educates various NFTChef and lunch them :)
 */
contract NFTMasterChef is Ownable, INFTMasterChef {
    // Second Skin NFT Staking Contract
    address public nftstaking;
    // ALTAVA TOKEN (TAVA)
    address public stakedToken;

    // deployed chef total count
    uint256 public totalCount;
    // id => deployed chef address
    mapping(uint256 => address) private _chefAddress;
    // check index of nftchef
    mapping(address => uint256) private _subChefs;

    // Deployed new chef Event
    event NewNFTChefContract(string chefId, address chef, string rewardNFT);

    /// @notice Check if target address is zero address
    modifier _realAddress(address addr) {
        require(addr != address(0), "Cannot be zero address");
        _;
    }

    /// @dev Constructore
    /// @param _stakedToken: stake token address (TAVA)
    /// @param _nftstaking: NFTStaking contract address
    constructor(
        address _stakedToken,
        address _nftstaking
    ) _realAddress(_stakedToken) _realAddress(_nftstaking) {
        require(IERC20(_stakedToken).totalSupply() >= 0, "Invalid token");
        nftstaking = _nftstaking;
        stakedToken = _stakedToken;
    }

    /**
     * @notice set/update NFTStaking contract
     * @param _nftstaking: NFTStaking contract address
     */
    function setNFTStaking(
        address _nftstaking
    ) external _realAddress(_nftstaking) onlyOwner {
        nftstaking = _nftstaking;
    }

    /**
     * @dev deploy the new NFTChef contract
     * @param _id `NFTChefs` table unique objectId
     * Data ID from off-chain database to just identify
     * @param _rewardNFT: reward token address
     * Here, reward NFT is airdropped from various chains
     * so use string but not address
     */
    function deploy(
        string memory _id,
        string memory _rewardNFT,
        uint256[] calldata _booster
    ) external onlyOwner {
        bytes memory rewardNFTStringBytes = bytes(_rewardNFT); // Uses memory

        require(rewardNFTStringBytes.length > 0, "Cannot be zero address");
        for (uint256 i = 0; i < _booster.length; i++) {
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
        totalCount = totalCount + 1;
        _chefAddress[totalCount] = nftChefAddress;
        _subChefs[nftChefAddress] = totalCount;

        // emit event
        emit NewNFTChefContract(_id, nftChefAddress, _rewardNFT);
    }

    /**
     * @notice get chef address with index
     */
    function getChefAddress(
        uint256 id
    ) external view override returns (address) {
        require(totalCount >= id && id > 0, "Chef: not exist");
        return _chefAddress[id];
    }

    /**
     * @notice get all smartchef contract's address
     */
    function getAllChefAddress()
        external
        view
        override
        returns (address[] memory)
    {
        address[] memory subchefAddress = new address[](totalCount);

        // Index starts from 1 but not 0
        for (uint256 i = 1; i <= totalCount; i++) {
            subchefAddress[i - 1] = _chefAddress[i];
        }
        return subchefAddress;
    }
}
