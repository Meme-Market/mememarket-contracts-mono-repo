// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MemeMarket is ERC1155, AccessControl {

    uint256 public constant ONE_TOKEN =  (10 ** 6);
    uint256 public constant ONE_CURRENCY_TOKEN =  (10 ** 18);

    uint256 public constant COST_PER_TOKEN = (10 ** 16);

    address public constant MEME_MARKET_FEE_ADDRESS = 0x212D3f1a1F31f86d87dA3361B12F31bFC0dfa891;

    IERC20 public currencyToken;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    // Mapping from Meme ID to Meme Tokens
    mapping (string => uint256) public memeTokens;

    // Mapping from Meme Tokens to Prices in MEEM ERC20 Token
    mapping (uint256 => uint256) public memeTokenPrices;

    constructor()
        ERC1155("")
    {
        currencyToken = IERC20(0x8fFD55FBa9caDB8d018b2E2E021D086AA690e88e);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MODERATOR_ROLE, msg.sender);
    }

    function createMeme(
        string memory _memeId
    ) public onlyRole(MODERATOR_ROLE) {
        require(uint256(memeTokens[_memeId]) == 0, "Meme already exists!");

        _tokenIds.increment();
        uint256 _newTokenId = _tokenIds.current();

        memeTokens[_memeId] = _newTokenId;
        memeTokenPrices[_newTokenId] = 0;
    }

    function setURI(
        string memory _newuri
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(_newuri);
    }

    function getBuyPrice(string memory _memeId) public view returns (uint256) {
        return memeTokenPrices[memeTokens[_memeId]] + COST_PER_TOKEN;
    }

    function buy(string memory _memeId, uint256 _funds) public {
        require(uint256(memeTokens[_memeId]) > 0, "Meme doesn't exist!");

        uint256 _currentPrice = getBuyPrice(_memeId);

        require( _funds >= _currentPrice, "Insufficient funds provided!" );

        uint256 _totaltokensToBuy = 1;
        uint256 _totalBuyPrice = _currentPrice;
        uint256 _newPrice = _currentPrice;

        while(true) {

            uint256 _tempNewPrice = _newPrice + COST_PER_TOKEN;
            uint256 _tenpTotalBuyPrice = _totalBuyPrice + _tempNewPrice;

            if(_funds < _tenpTotalBuyPrice) {
                break;
            }

            _newPrice += COST_PER_TOKEN;
            _totalBuyPrice += _newPrice;
            _totaltokensToBuy++; 
        }

        /*
        uint256 _allowance = currencyToken.allowance(msg.sender, address(this));
        if(_totalBuyPrice < _allowance) {
            currencyToken.approve(address(this), _totalBuyPrice - _allowance);
        }
        */
        
        // Need to integrate charging people w/ $MEEM erc20 token
        //currencyToken.transferFrom(msg.sender, address(this), _amount);

        uint256 _tokenId = memeTokens[_memeId];
        _mint(msg.sender, _tokenId, _totaltokensToBuy * ONE_TOKEN, '');

        _updateMemeTokenPrice(_tokenId, _newPrice);  
    }

    function getSellPrice(string memory _memeId) public view returns (uint256) {
        return memeTokenPrices[memeTokens[_memeId]];
    }

    function sell(string memory _memeId, uint256 _tokensToSell) public {
        require(uint256(memeTokens[_memeId]) > 0, "Meme doesn't exist!");

        // check to make sure sender has enough token balance

        uint256 _currentPrice = getSellPrice(_memeId);

        require( _tokensToSell > 0, "Need higher than 1 tokens to sell!" );

        uint256 _totaltokensToSell = 0;
        uint256 _totalSellPrice = _currentPrice;
        uint256 _newPrice = _currentPrice;

        while(true) {

            //uint256 _tempNewPrice = _newPrice - COST_PER_TOKEN;
            //uint256 _tenpTotalSellPrice = _totalSellPrice + _tempNewPrice;

            if(_totaltokensToSell >= _tokensToSell) {
                break;
            }

            _newPrice -= COST_PER_TOKEN;
            _totalSellPrice += _newPrice;
            _totaltokensToSell += ONE_TOKEN; 
        }

        // Need to integrate refunding people w/ $MEEM erc20 token
        //currencyToken.transferFrom(msg.sender, address(this), _amount);

        uint256 _tokenId = memeTokens[_memeId];
        _burn(msg.sender, _tokenId, _totaltokensToSell);

        _updateMemeTokenPrice(_tokenId, _newPrice);
    }

    // Assume names are unique for now
    function getTokenId(string memory _memeId) public view returns (uint256) {
        return memeTokens[_memeId];
    }

    function _updateMemeTokenPrice(uint256 _tokenId, uint256 amount) private {
        memeTokenPrices[_tokenId] = amount;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

}