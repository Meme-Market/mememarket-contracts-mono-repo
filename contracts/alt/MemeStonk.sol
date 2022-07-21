// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MemeStonk is ERC1155, AccessControl {

    uint256 public constant ONE_TOKEN =  (10 ** 6);
    uint256 public constant ONE_CURRENCY_TOKEN =  (10 ** 18);
    uint256 public constant COST_PER_TOKEN = (10 ** 16);
    uint256 public constant BASE_PERCENTAGE = 100;

    uint256 public platformFeePercentage = 0;
    address public platformFeeAddress;

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
        currencyToken = IERC20(0xd9145CCE52D386f254917e481eB44e9943F39138);

        platformFeePercentage = uint256(5);
        platformFeeAddress = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MODERATOR_ROLE, msg.sender);
    }

    function setURI(
        string memory _newuri
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(_newuri);
    }

    function setPlatformFee(
        uint256 _newFee
    ) public onlyRole(ADMIN_ROLE) {
        platformFeePercentage = _newFee;
    }

    function setPlatformFeeAddress(
        address _address
    ) public onlyRole(ADMIN_ROLE) {
        platformFeeAddress = _address;
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

    function getBuyPrice(string memory _memeId) public view returns (uint256) {
        require(uint256(memeTokens[_memeId]) > 0, "Meme doesn't exist!");

        return memeTokenPrices[memeTokens[_memeId]] + COST_PER_TOKEN;
    }

    function calculateBuyPrice(string memory _memeId, uint256 _shares) public view returns (uint256, uint256, uint256, uint256) {
        require(uint256(memeTokens[_memeId]) > 0, "Meme doesn't exist!");

        uint256 _currentPrice = getBuyPrice(_memeId);

        uint256 _sharesToBuy = ONE_TOKEN;
        uint256 _totalPrice = _currentPrice;
        uint256 _newPrice = _currentPrice;
        
        while(true) {

            if(_sharesToBuy >= _shares) {
                break;
            } 

            _newPrice += COST_PER_TOKEN;
            _totalPrice += _newPrice;
            _sharesToBuy += ONE_TOKEN;
        }

        uint256 _totalFee = SafeMath.div((_totalPrice * platformFeePercentage), BASE_PERCENTAGE);
        uint256 _grandTotal = (_totalPrice + _totalFee);

        return (_totalPrice, _totalFee, _grandTotal, _newPrice);
    }

    function buy(string memory _memeId, uint256 _shares) public payable {
        require(uint256(memeTokens[_memeId]) > 0, "Meme doesn't exist!");

        (, uint256 _totalFee, uint256 _grandTotal, uint256 _newPrice) = calculateBuyPrice(_memeId, _shares);

        require(currencyToken.balanceOf(msg.sender) >= _grandTotal, "You have insufficient funds!");
        require(_getAllowance() >= _grandTotal, "Insufficient allowance!");

        currencyToken.transferFrom(msg.sender, address(this), _grandTotal);

        // Collect platform fee
        currencyToken.transfer(platformFeeAddress, _totalFee);

        uint256 _tokenId = memeTokens[_memeId];
        _mint(msg.sender, _tokenId, _shares, '');

        _updateMemeTokenPrice(_tokenId, _newPrice);  
    }

    function getSellPrice(string memory _memeId) public view returns (uint256) {
        require(uint256(memeTokens[_memeId]) > 0, "Meme doesn't exist!");

        return memeTokenPrices[memeTokens[_memeId]];
    }

    function calculateSellPrice(string memory _memeId, uint256 _shares) public view returns (uint256, uint256, uint256, uint256) {
        require(uint256(memeTokens[_memeId]) > 0, "Meme doesn't exist!");

        uint256 _currentPrice = getSellPrice(_memeId);

        uint256 _sharesToSell = 0;
        uint256 _totalPrice = _currentPrice;
        uint256 _newPrice = _currentPrice;
        
        while(true) {

            if(_sharesToSell >= _shares || _totalPrice <= 0) {
                break;
            }

            _newPrice -= COST_PER_TOKEN;
            _totalPrice += _newPrice;
            _sharesToSell += ONE_TOKEN; 
        }

        uint256 _totalFee = SafeMath.div((_totalPrice * platformFeePercentage), BASE_PERCENTAGE);
        uint256 _grandTotal = (_totalPrice - _totalFee);

        return (_totalPrice, _totalFee, _grandTotal, _newPrice);
    }

    function sell(string memory _memeId, uint256 _shares) public {
        require(uint256(memeTokens[_memeId]) > 0, "Meme doesn't exist!");

        (, uint256 _totalFee, uint256 _grandTotal, uint256 _newPrice) = calculateSellPrice(_memeId, _shares);

        require(currencyToken.balanceOf(address(this)) >= _grandTotal, "Platform has insufficient funds!");

        // Collect platform fee
        currencyToken.transfer(platformFeeAddress, _totalFee);

        currencyToken.transfer(msg.sender, _grandTotal);

        uint256 _tokenId = memeTokens[_memeId];
        _burn(msg.sender, _tokenId, _shares);

        _updateMemeTokenPrice(_tokenId, _newPrice);
    }

    // Assume names are unique for now
    function getTokenId(string memory _memeId) public view returns (uint256) {
        return memeTokens[_memeId];
    }

    function _updateMemeTokenPrice(uint256 _tokenId, uint256 amount) private {
        memeTokenPrices[_tokenId] = amount;
    }

    function _getAllowance() private view returns(uint256){
        return currencyToken.allowance(msg.sender, address(this));
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