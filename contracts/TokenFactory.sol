//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.9.0;

// custom defined interface
import "./ThirdPartyToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Test Token Generator
 */
contract TokenFactory is Ownable{
    constructor() {}

    event NewToken(address indexed new_nft);

    function deploy(
        string memory _name, 
        string memory _symbol 
    ) external onlyOwner {
        ThirdPartyToken thirdPartyToken = new ThirdPartyToken(
            _name, 
            _symbol
        );

        emit NewToken(address(thirdPartyToken));
    }
}