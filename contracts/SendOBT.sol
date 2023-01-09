//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

// Replace "SendOBT" with the name of your token
contract SendOBT is Ownable {
    using SafeERC20 for IERC20Metadata;

    // Declare variables
    uint256 public totalSupply;
    uint256 public tokenAmount = 15000 ether;
    mapping(address => uint256) public balanceOf;

    IERC20Metadata public TAVA;

    // Initialize variables
    constructor() {}

    function updateTavaAddress(address _tava) external onlyOwner {
        require(_tava != address(0x0), "Invalid address");
        TAVA = IERC20Metadata(_tava);
    }

    function updateTokenAmount(uint256 _tokenAmount) external onlyOwner {
        require(_tokenAmount != 0, "Invalid address");
        tokenAmount = _tokenAmount;
    }

    // Function to send test tokens to a specified number of addresses
    function sendTestTokens(address[] memory addresses) external onlyOwner {
        require(addresses.length <= 500, "Too many addresses!");
        for (uint i = 0; i < addresses.length; i++) {
            TAVA.safeTransferFrom(address(this), addresses[i], tokenAmount);
        }
    }
}
