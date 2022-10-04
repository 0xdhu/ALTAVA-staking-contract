//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.9.0;

// custom defined interface
import "./SmartChef.sol";

/**
 * @dev MasterChef educates various SmartChef and lunch them :)
 */
contract MasterChef is Ownable{
    using SafeMath for uint256;    

    // Staked Event
    event NewSmartChefContract(
        address indexed smartChef,
        address indexed rewardToken,
        address indexed stakedToken,
        address admin
    );
    
    constructor () { }

    /**
     * @dev deploy the new SmartChef
     */
    function deploy(
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
            abi.encode()
        );
        bytes32 salt = keccak256(abi.encodePacked());

        address smartChefAddress;

        assembly {
            smartChefAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
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
            msg.sender
        );

        // emit event
        emit NewSmartChefContract(smartChefAddress, address(_rewardToken), address(_stakedToken), _admin);
    }
}