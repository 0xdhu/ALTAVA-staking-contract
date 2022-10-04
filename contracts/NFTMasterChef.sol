//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.9.0;

// custom defined interface
import "./NFTChef.sol";

/**
 * @dev NFT MasterChef educates various NFTChef and lunch them :)
 */
contract NFTMasterChef is Ownable{
    using SafeMath for uint256;    

    // Staked Event
    event NewNFTChefContract(
        address indexed nftChef,
        address indexed rewardNFT,
        address indexed stakedToken,
        address admin
    );
    
    constructor () { }

    /**
     * @dev deploy the new NFTChef
     */
    function deploy(
        IERC20 _stakedToken,
        address _rewardNFT,
        address _admin
    ) external onlyOwner {
        require(_stakedToken.totalSupply() >= 0);
        require(_rewardNFT != address(0x0));
        require(_admin != address(0x0));

        bytes memory bytecode = type(NFTChef).creationCode;
        // pass constructor argument
        bytecode = abi.encodePacked(
            bytecode,
            abi.encode()
        );
        bytes32 salt = keccak256(abi.encodePacked());
        address nftChefAddress;

        assembly {
            nftChefAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        
        NFTChef(nftChefAddress).initialize(
            address(_stakedToken),
            _rewardNFT,
            _admin,
            msg.sender
        );

        // emit event
        emit NewNFTChefContract(nftChefAddress, _rewardNFT, address(_stakedToken), _admin);
    }
}