code = """// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTminimint is ERC721, ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter;
    uint256 public mintFee = 0.01 ether;

    event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI);
    event MintFeeUpdated(uint256 oldFee, uint256 newFee);

    constructor() ERC721("NFTminimint", "NFTM") Ownable(msg.sender) {}

    function mintNFT(address to, string memory tokenURI) external payable {
        require(msg.value >= mintFee, "Insufficient minting fee");
        
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        emit NFTMinted(to, tokenId, tokenURI);
    }

    function setMintFee(uint256 _mintFee) external onlyOwner {
        uint256 oldFee = mintFee;
        mintFee = _mintFee;
        emit MintFeeUpdated(oldFee, _mintFee);
    }

    function getTokenURI(uint256 tokenId) external view returns (string memory) {
        return tokenURI(tokenId);
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }

    // Override functions
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Withdraw function for owner
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Transfer failed");
    }
}
"""
import os
path = "/Users/apple/Desktop/SpinDBoard/NFTminimint/contracts/NFTminimint.sol"
with open(path, "w") as f:
    f.write(code)
    print(f"Successfully wrote to {path}")
