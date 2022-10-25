/**
 * This ThirdPartyToken is just test purpose contract
 */
//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// This is the main building block for smart contracts.
contract ThirdPartyToken is ERC20{
    // The fixed amount of tokens, stored in an unsigned integer type variable.
    uint256 public initialSupply = 1000000 * 1e18;
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, initialSupply);
    }
}