// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MemeERC721 is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;
    mapping (uint256 => string) private _tokenURIs;


    mapping (string => bool) private _moderated;
    function approveMeme(string memory _tokenURI) public {
        _moderated[_tokenURI] = true;
    }
    function disableMeme(string memory _tokenURI) public {
        _moderated[_tokenURI] = false;
    }


    constructor() ERC721("DistractedBoyfriendMeme", "MEME_NFT_DB") {}

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
    }

    function mint(address recipient, string memory ipfs_uri) public returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, ipfs_uri);

        return newItemId;
    }
}
