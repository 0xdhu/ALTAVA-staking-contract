//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./SmartChef.sol";

/**
 * @notice MasterChef educates various SmartChef and lunch them :)
 * @dev MasterChef contract deploy sub smartchef contracts
 * Each smartchef contract is unique for each rewards token
 */
contract MasterChef is Ownable {
    /// Second Skin NFT Staking Contract
    address public nftstaking;
    /// Total count of deployed chef contracts
    uint256 public totalCount;
    /// counter index => deployed chef address
    mapping(uint256 => address) public chefAddress;
    /// deployed chef address => counter index
    mapping(address => uint256) private _subchefIndexs;

    /// @dev Even whenever MasterChef deploy new smartchef
    /// @param id: Data ID from off-chain database to just identify
    event NewSmartChefContract(
        string id,
        address indexed smartChef,
        address indexed stakedToken,
        string rewardToken,
        bool rewardByAirdrop
    );

    /// @notice Check if target address is zero address
    modifier _realAddress(address addr) {
        require(addr != address(0x0), "Cannot be zero address");
        _;
    }

    /// @dev Constructore
    /// @param _nftstaking: NFTStaking contract address
    constructor(address _nftstaking) _realAddress(_nftstaking) {
        nftstaking = _nftstaking;
    }

    /**
     * @notice set/update NFTStaking contract
     * @param _nftstaking: NFTStaking contract address
     */
    function setNFTStaking(address _nftstaking)
        external
        _realAddress(_nftstaking)
        onlyOwner
    {
        nftstaking = _nftstaking;
    }

    /**
     * @dev deploy the new SmartChef contract
     * @param _id: Data ID from off-chain database to just identify
     * @param _reward: Reward token address. This can be used in case
     * Reward token is coming from other chains. Just notify address to users.
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _bonusEndBlock: end block
     * @param _rewardByAirdrop: If reward token is coming from other chains
     * @param _boosterController: BoosterController contract address
     * In this case, reward token would be airdropped
     */
    function deploy(
        string memory _id,
        string memory _reward,
        IERC20Metadata _stakedToken,
        IERC20Metadata _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        bool _rewardByAirdrop,
        address _boosterController
    ) external onlyOwner {
        require(_stakedToken.totalSupply() >= 0, "Invalid token");

        if (!_rewardByAirdrop) {
            require(_rewardToken.totalSupply() >= 0, "Invalid token");
        } else {
            bytes memory rewardStringBytes = bytes(_reward); // Uses memory

            require(rewardStringBytes.length > 0, "Cannot be zero address");
        }

        bytes memory bytecode = type(SmartChef).creationCode;
        // pass constructor argument
        bytecode = abi.encodePacked(
            bytecode,
            abi.encode(_stakedToken, _rewardToken, _reward, _rewardByAirdrop)
        );
        bytes32 salt = keccak256(abi.encodePacked());

        address smartChefAddress;

        assembly {
            smartChefAddress := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }

        SmartChef(smartChefAddress).initialize(
            _stakedToken,
            _rewardToken,
            _reward,
            _rewardPerBlock,
            _startBlock,
            _bonusEndBlock,
            msg.sender,
            nftstaking,
            _rewardByAirdrop,
            _boosterController
        );

        // register address
        totalCount = totalCount + 1;
        chefAddress[totalCount] = smartChefAddress;
        _subchefIndexs[smartChefAddress] = totalCount;

        // emit event
        emit NewSmartChefContract(
            _id,
            smartChefAddress,
            address(_stakedToken),
            _reward,
            _rewardByAirdrop
        );
    }

    /**
     * @notice get all smartchef contract's address
     */
    function getAllChefAddress() external view returns (address[] memory) {
        address[] memory subchefAddress = new address[](totalCount);

        // Index starts from 1 but not 0
        for (uint256 i = 1; i <= totalCount; i++) {
            subchefAddress[i - 1] = chefAddress[i];
        }
        return subchefAddress;
    }
}
