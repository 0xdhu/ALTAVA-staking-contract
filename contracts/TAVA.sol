/**
 * This TAVA is just test purpose contract in only testnet
 */
//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "hardhat/console.sol";

// This is the main building block for smart contracts.
contract TAVA is ERC20{
    // The fixed amount of tokens, stored in an unsigned integer type variable.
    uint256 public initialSupply = 1000000 * 1e18;
    constructor() ERC20("ALTAVA TOKEN", "TAVA") {
        _mint(msg.sender, initialSupply);
    }
}