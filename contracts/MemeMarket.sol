// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MemeMarket is ERC1155 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping (string => uint256) private _memeNameIdMap;
    mapping (uint256 => uint256) private _memePriceMap;

    constructor() public ERC1155("") {}


    // onlyOwner modifier add
    function mint(string memory memeName, string memory memeImageURI) public {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(address(this), newItemId, 1 * (10 ** 6), '');
        _setURI(memeImageURI);
        _memeNameIdMap[memeName] = newItemId;
        _memePriceMap[newItemId] = 0;
    }

    // to address must call setApprovalForAll
    function tradeBuyMeme(uint256 memeId, uint256 amount) public {
        require(balanceOf(address(this), memeId) >= amount);
        safeTransferFrom(address(this), msg.sender, memeId, amount, '');
        _updateMemePrice(memeId, 10 * amount, true);
    }

    function tradeSellMeme(uint256 memeId, uint256 amount) public {
        safeTransferFrom(msg.sender, address(this), memeId, amount, '');
        _updateMemePrice(memeId, 10 * amount, false);
    }

    // Assume names are unique for now
    function getMemeId(string memory memeName) public view returns (uint256) {
        return _memeNameIdMap[memeName];
    }

    function _updateMemePrice(uint256 memeId, uint256 amount, bool action) private {
        if (action) {
            _memePriceMap[memeId] += amount;
        } else {
            _memePriceMap[memeId] -= amount;
        }
    }

    function getNumTokensForOneNFTShare(uint256 memeId) public view returns (uint256) {
        return _memePriceMap[memeId];
    }

    // Handle ERC20 balance
}