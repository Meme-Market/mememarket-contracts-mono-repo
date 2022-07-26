// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MemeStonk is ERC1155, AccessControl {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    uint256 public constant ONE_TOKEN =  (10 ** 6);
    uint256 public constant ONE_CURRENCY_TOKEN =  (10 ** 18);
    uint256 public constant COST_PER_TOKEN = (10 ** 16);
    uint256 public constant BASE_PERCENTAGE = 100;

    struct MemeData {
        // @notice Author of the meme
        address author;
        // @notice Flag whether a meme is active
        bool active;
        // @notice Stonk token id
        uint256 stonkTokenId;
        // @notice Stonk token price in $MEEM tokens
        uint256 stonkTokenPrice;
        // @notice Flag whether trading on a meme is active
        bool tradingActive;
    }

    // @notice Mapping from Meme ID to MemeData
    mapping(bytes32 => MemeData) public memes;

    IERC20 public collateralToken;

    uint256 public platformFeePercentage = 0;
    address public platformFeeAddress;

    constructor(
        address _collateralToken, 
        uint256 _platformFee, 
        address _platformFeeAddress
    ) ERC1155("") {
        collateralToken = IERC20(_collateralToken);

        platformFeePercentage = _platformFee;
        platformFeeAddress = _platformFeeAddress;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MODERATOR_ROLE, msg.sender);
    }

    /*///////////////////////////////////////////////////////////////////
    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////////*/

    function setURI(
        string memory _newuri
    ) public onlyRole(ADMIN_ROLE) {
        _setURI(_newuri);
    }

    function setCollateralToken(
        address _contractAddress
    ) public onlyRole(ADMIN_ROLE) {
        collateralToken = IERC20(_contractAddress);
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
        string memory _memeUUID,
        address _author
    ) public onlyRole(MODERATOR_ROLE) returns (bytes32) {
        
        bytes32 _memeId = getMemeId(_memeUUID);

        require(!isInitialized(_memeId), "Meme already exists!");

        uint256 _newTokenId = getTokenId(_memeId);

        memes[_memeId] = MemeData({
            author: _author,
            active: true,
            stonkTokenId: _newTokenId,
            stonkTokenPrice: uint256(0),
            tradingActive: true
        });

        return _memeId;
    }

    function getSingleStonkBuyPrice(
        bytes32 _memeId
    ) public view returns (uint256) {
        require(isInitialized(_memeId), "Meme doesn't exist!");

        return memes[_memeId].stonkTokenPrice + COST_PER_TOKEN;
    }

    function getStonkBuyPrices(
        bytes32 _memeId, 
        uint256 _shares
    ) public view returns (uint256, uint256, uint256, uint256) {
        uint256 _currentPrice = getSingleStonkBuyPrice(_memeId);

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

    function buyStonks(
        bytes32 _memeId,
        uint256 _shares
    ) public payable {
        (, uint256 _totalFee, uint256 _grandTotal, uint256 _newPrice) = getStonkBuyPrices(_memeId, _shares);

        require(collateralToken.balanceOf(msg.sender) >= _grandTotal, "You have insufficient funds!");
        require(_getAllowance() >= _grandTotal, "Insufficient allowance!");

        collateralToken.transferFrom(msg.sender, address(this), _grandTotal);

        // Collect platform fee
        collateralToken.transfer(platformFeeAddress, _totalFee);

        uint256 _tokenId = memes[_memeId].stonkTokenId;
        _mint(msg.sender, _tokenId, _shares, '');

        _updateStonkTokenPrice(_memeId, _newPrice);  
    }

    function getSingleStonkSellPrice(
        bytes32 _memeId
    ) public view returns (uint256) {
        require(isInitialized(_memeId), "Meme doesn't exist!");

        return memes[_memeId].stonkTokenPrice;
    }

    function getStonkSellPrices(
        bytes32 _memeId,
        uint256 _shares
    ) public view returns (uint256, uint256, uint256, uint256) {
        uint256 _currentPrice = getSingleStonkSellPrice(_memeId);

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

    function sellStonk(
        bytes32 _memeId, 
        uint256 _shares
    ) public {
        (, uint256 _totalFee, uint256 _grandTotal, uint256 _newPrice) = getStonkSellPrices(_memeId, _shares);

        require(collateralToken.balanceOf(address(this)) >= _grandTotal, "Contract has insufficient funds!");

        // Collect platform fee
        collateralToken.transfer(platformFeeAddress, _totalFee);

        collateralToken.transfer(msg.sender, _grandTotal);

        uint256 _tokenId = memes[_memeId].stonkTokenId;
        _burn(msg.sender, _tokenId, _shares);

        _updateStonkTokenPrice(_memeId, _newPrice);
    }

    function getMemeId(
        string memory _memeUUID
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), _memeUUID));
    }

    function getTokenId(
        bytes32 _memeId
    ) public view returns (uint256) {
        return  uint256(keccak256(abi.encodePacked(address(this), _memeId)));
    }

    function isInitialized(
        bytes32 _memeId
    ) public view returns (bool) {
        return memes[_memeId].stonkTokenId > 0;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address, 
        address, 
        uint256, 
        uint256, 
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, 
        address, 
        uint256[] memory, 
        uint256[] memory, 
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address, 
        address, 
        uint256, 
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /*///////////////////////////////////////////////////////////////////
    PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////*/

    function _updateStonkTokenPrice(
        bytes32 _memeId, 
        uint256 amount
    ) private {
        memes[_memeId].stonkTokenPrice = amount;
    }

    function _getAllowance() private view returns(uint256){
        return collateralToken.allowance(msg.sender, address(this));
    }
}