// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// checking ownership
error SecondSkinNFT__InvalidCreator();
// checking if the mint amount is > 0
error SecondSkinNFT__InvalidMintAmount();
// checking if the mint amount match the number of token uri
error SecondSkinNFT__InvalidParams();
// checking if the price is >= 0;
error SecondSkinNFT__InvalidPrice();
// only owner
error SecondSkinNFT__InvalidOwner();

/**
 * @title ALTAVA's own NFT contract
 */
contract SecondSkinNFT is ERC721URIStorage {
    // helper function
    using Strings for uint256;

    // This event can be catched by the front-end to keep track of any activities
    event Minted(uint indexed tokenId, string indexed tokenUri);

    // assign an ownership
    address private owner;
    // keep track of token id
    uint private tokenCounter;
    // keep track of user commission in percentage
    uint private commissionPercentage;
    //keep track of each NFT price
    mapping(uint => uint) private itemPrice;
    // marketplace address for approval
    address private marketplaceAddress;

    // create an instance of ERC721 and ownership
    constructor(
        address _owner,
        address _marketplaceAddress
    ) ERC721("ALTAVA SecondSkinNFT", "SecondSkinNFT") {
        owner = _owner;
        marketplaceAddress = _marketplaceAddress;
    }

    // checking if the amount is valid
    modifier validAmount(uint _amount) {
        if (_amount <= 0) revert SecondSkinNFT__InvalidMintAmount();
        _;
    }

    // checking if the price is valid
    modifier validPrice(uint _price) {
        if (_price <= 0) revert SecondSkinNFT__InvalidPrice();
        _;
    }

    // make sure only owner can do it
    modifier onlyOwner() {
        if (msg.sender != owner) revert SecondSkinNFT__InvalidOwner();
        _;
    }

    /**
     * @notice This function will allow creator to set their NFTs with a single price
     *         instead of set the price 1 by 1 manually
     * @param _price -> the price creator want to set
     */
    function setAllNftPrice(uint _price) external validPrice(_price) onlyOwner {
        // set the same price for all NFTs
        uint totalSupply = tokenCounter;
        for (uint i = 0; i < totalSupply; i++) {
            itemPrice[i] = _price;
        }
    }

    /**
     * @notice This mint function will allow users to mint their own NFTs, only creator can mint
     * @dev Token id will start from 0
     * @param _tokenUri -> the address pointing to the off-chain storage
     */
    function mint(string memory _tokenUri) public onlyOwner {
        //perform mint actions
        uint currentTokenId = tokenCounter;
        tokenCounter++;
        _safeMint(msg.sender, currentTokenId);
        _setTokenURI(currentTokenId, _tokenUri);
        emit Minted(currentTokenId, _tokenUri);
    }

    /**
     * @notice See who own this contract
     * @return owner -> creator who create a collection
     */
    function getCreator() public view returns (address) {
        return owner;
    }

    /**
     * @notice Query the total NFT the creator has minted
     * @return tokenCounter -> total minted NFT ie 2 = 2 NFT minted
     */
    function getTotalSupply() public view returns (uint) {
        return tokenCounter;
    }

    /**
     * @notice This will retrieve the price for a specific NFT
     * @param _tokenId -> which NFT to look for
     * @return itemPrice -> the price of the given NFT
     */
    function getItemPrice(uint _tokenId) public view returns (uint) {
        return itemPrice[_tokenId];
    }
}