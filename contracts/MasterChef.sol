//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./SmartChef.sol";

/**
 * @dev MasterChef educates various SmartChef and lunch them :)
 */
contract MasterChef is Ownable {
    using SafeMath for uint256;

    // Second Skin NFT Staking Contract
    address public nftstaking;
    // deployed chef total count
    uint256 public total_count;
    // id => deployed chef address
    mapping(uint256 => address) private chefAddress;

    // Staked Event
    event NewSmartChefContract(
        string id,
        address indexed smartChef,
        address indexed rewardToken,
        address indexed stakedToken,
        address admin
    );

    event Stake(
        address chef,
        address indexed sender,
        uint256 lockedAmount,
        uint256 lockStartTime,
        uint256 lockEndTime,
        uint256 lastUserActionTime,
        uint256 rewards,
        uint256 rewardDebt,
        uint256 boosterValue
    );
    event Unstaked(
        address chef,
        address indexed sender,
        uint256 lastUserActionTime,
        uint256 rewards,
        uint256 boosterValue
    );

    modifier onlySubChef() {
        bool isSubChef = false;
        for (uint256 i = 0; i < total_count; i++) {
            if (chefAddress[i] == msg.sender) {
                isSubChef = true;
            }
        }
        require(isSubChef, "Role: not sub chef");
        _;
    }

    constructor(address _nftstaking) {
        require(
            _nftstaking != address(0x0),
            "Address should not be zero address"
        );
        nftstaking = _nftstaking;
    }

    /**
     * set nftstaking contract address
     */
    function setNFTStaking(address _nftstaking) external onlyOwner {
        require(
            _nftstaking != address(0x0),
            "Address should not be zero address"
        );
        nftstaking = _nftstaking;
    }

    /**
     * @dev deploy the new SmartChef
     */
    function deploy(
        string memory _id,
        IERC20Metadata _stakedToken,
        IERC20Metadata _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _poolLimitPerUser,
        uint256 _numberBlocksForUserLimit,
        address _admin
    ) external onlyOwner {
        require(_stakedToken.totalSupply() >= 0);
        require(_rewardToken.totalSupply() >= 0);
        require(_admin != address(0x0));

        bytes memory bytecode = type(SmartChef).creationCode;
        // pass constructor argument
        bytecode = abi.encodePacked(
            bytecode,
            abi.encode(_stakedToken, _rewardToken)
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
            _rewardPerBlock,
            _startBlock,
            _bonusEndBlock,
            _poolLimitPerUser,
            _numberBlocksForUserLimit,
            _admin,
            msg.sender,
            nftstaking
        );

        // register address
        chefAddress[total_count] = smartChefAddress;
        total_count = total_count.add(1);

        // emit event
        emit NewSmartChefContract(
            _id,
            smartChefAddress,
            address(_rewardToken),
            address(_stakedToken),
            _admin
        );
    }

    /**
     * get chef address with id
     */
    function getChefAddress(uint256 id) external view returns (address) {
        require(total_count > id, "Chef: not exist");
        return chefAddress[id];
    }

    /**
     * Emit event from sub chef: Staked
     */
    function emitStakedEventFromSubChef(
        address sender,
        uint256 lockedAmount,
        uint256 lockStartTime,
        uint256 lockEndTime,
        uint256 lastUserActionTime,
        uint256 rewards,
        uint256 rewardDebt,
        uint256 boosterValue
    ) external onlySubChef {
        emit Stake(
            msg.sender,
            sender,
            lockedAmount,
            lockStartTime,
            lockEndTime,
            lastUserActionTime,
            rewards,
            rewardDebt,
            boosterValue
        );
    }

    /**
     * Emit event from sub chef: Unstaked
     */
    function emitUnstakedEventFromSubChef(
        address sender,
        uint256 lastUserActionTime,
        uint256 rewards,
        uint256 boosterValue
    ) external onlySubChef {
        emit Unstaked(
            msg.sender,
            sender,
            lastUserActionTime,
            rewards,
            boosterValue
        );
    }
}
