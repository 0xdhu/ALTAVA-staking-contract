/**
 * This NFTFactory is just test purpose contract in only testnet
 */
//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.9.0;

// custom defined interface
import "./ThirdPartyNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev TestNFT Token Generator
 */
contract NFTFactory is Ownable{
    constructor() {}

    event NewNFT(address indexed new_nft);

    function deploy(
        string memory _name, 
        string memory _symbol 
    ) external onlyOwner {
        ThirdPartyNFT thirdPartyNFT = new ThirdPartyNFT(
            msg.sender,
            _name, 
            _symbol
        );

        emit NewNFT(address(thirdPartyNFT));
    }
}