/**
 * This TAVA is just test purpose contract in only testnet
 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// only owner
error SecondSkinNFT__InvalidOwner();

/**
 * @title ALTAVA's own NFT contract. This is just test purpoase NFT token contract in testnet.
 */
contract SecondSkinNFT is ERC721URIStorage {
    // helper function
    using Strings for uint256;

    // This event can be catched by the front-end to keep track of any activities
    event Minted(uint indexed tokenId, string indexed tokenUri);

    // assign an ownership
    address private _owner;
    // keep track of token id
    uint private tokenCounter;

    // create an instance of ERC721 and ownership
    constructor(
        address newOwner
    ) ERC721("ALTAVA SecondSkinNFT", "SecondSkinNFT") {
        _owner = newOwner;
    }

    // make sure only owner can do it
    modifier onlyOwner() {
        if (msg.sender != _owner) revert SecondSkinNFT__InvalidOwner();
        _;
    }

    /**
     * @notice This mint function will allow users to mint their own NFTs, only creator can mint
     * @dev Token id will start from 0
     * @param _tokenUri -> the address pointing to the off-chain storage
     */
    function mint(string memory _tokenUri) public onlyOwner {
        tokenCounter++;
        //perform mint actions
        uint currentTokenId = tokenCounter;
        _safeMint(msg.sender, currentTokenId);
        _setTokenURI(currentTokenId, _tokenUri);
        emit Minted(currentTokenId, _tokenUri);
    }

    /**
     * @notice See who own this contract
     * @return owner -> creator who create a collection
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Query the total NFT the creator has minted
     * @return tokenCounter -> total minted NFT ie 2 = 2 NFT minted
     */
    function getTotalSupply() public view returns (uint) {
        return tokenCounter;
    }
}