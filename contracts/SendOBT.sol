//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
interface IERC721Metadata {
    function mint(string memory _tokenUri) external;
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
// Replace "SendOBT" with the name of your token
contract SendOBT is Ownable {
    using SafeERC20 for IERC20Metadata;

    // Declare variables
    uint256 public totalSupply;
    uint256 public tokenAmount = 15000 ether;
    mapping(address => uint256) public balanceOf;

    IERC20Metadata public TAVA;
    IERC721Metadata public secondskinNFT;
    // Initialize variables
    constructor() {}

    function updateTavaAddress(address _tava) external onlyOwner{
        require(_tava != address(0x0), "Invalid address");
        TAVA = IERC20Metadata(_tava);
    }

    function updateAltavaSecondskinAddress(address _secondskinNFT) external onlyOwner{
        require(_secondskinNFT != address(0x0), "Invalid address");
        secondskinNFT = IERC721Metadata(_secondskinNFT);
    }

    // NFT batch mint
    function batchMint(string memory uri, uint256 count) external onlyOwner {
        for (uint256 i = 0; i < count; i++) {
            secondskinNFT.mint(uri);
        }
    }

    // Function to send test tokens to a specified number of addresses
    function sendTestTokens(address[] memory addresses) external onlyOwner {
        require(addresses.length <= 500, "Too many addresses!");
        for (uint i = 0; i < addresses.length; i++) {
            TAVA.safeTransferFrom(address(this), addresses[i], tokenAmount);
        }
    }

    function sendTestNFTs(address[] memory addresses, uint256 startNumber) external onlyOwner {
        require(addresses.length <= 500, "Too many addresses!");
        for (uint i = 0; i < addresses.length; i++) {
            uint256 tokenId = startNumber + i;
            secondskinNFT.safeTransferFrom(address(this), addresses[i], tokenId);
        }
    }
}