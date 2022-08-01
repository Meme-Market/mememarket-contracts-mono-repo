// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MemeStonk is Initializable, ERC1155Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {

    /*///////////////////////////////////////////////////////////////////
    EVENTS
    //////////////////////////////////////////////////////////////////*/

    event StonkBuy(
        address indexed buyer,
        bytes32 indexed memeId,
        uint256 totalStonks,
        uint256 totalPrice,
        uint256 totalFee,
        uint256 grandTotal
    );

    event StonkSell(
        address indexed seller,
        bytes32 indexed memeId,
        uint256 totalStonks,
        uint256 totalPrice,
        uint256 totalFee,
        uint256 grandTotal
    );

    event StonkPriceUpdated(
        bytes32 indexed memeId,
        uint256 newPrice
    );

    /*///////////////////////////////////////////////////////////////////
    CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////////*/

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    uint256 public constant ONE_STONK =  (10 ** 18);
    uint256 public constant ONE_COLLATERAL_TOKEN =  (10 ** 18);
    uint256 public constant COST_PER_STONK = (10 ** 16);
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

    /*///////////////////////////////////////////////////////////////////
    VARIABLES
    //////////////////////////////////////////////////////////////////*/

    // @notice Mapping from Meme ID to MemeData
    mapping(bytes32 => MemeData) public memes;

    IERC20 public collateralToken;

    uint256 public platformFeePercentage = 0;
    address public platformFeeAddress;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _collateralToken, 
        uint256 _platformFee, 
        address _platformFeeAddress
    ) initializer public {
        __ERC1155_init("");
        __AccessControl_init();
        __UUPSUpgradeable_init();

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

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(ADMIN_ROLE)
        override
    {}

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

        require(!isCreated(_memeId), "Meme already exists!");

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
        require(isCreated(_memeId), "Meme doesn't exist!");

        return memes[_memeId].stonkTokenPrice + COST_PER_STONK;
    }

    function getStonkBuyPrices(
        bytes32 _memeId, 
        uint256 _stonks
    ) public view returns (uint256, uint256, uint256, uint256, uint256) {
        require(_stonks >= ONE_STONK, "Need quantity of one stonk or greater");

        uint256 _totalStonks = Math.ceilDiv(_stonks, ONE_STONK) * ONE_STONK;

        uint256 _currentPrice = getSingleStonkBuyPrice(_memeId);

        uint256 _stonksToBuy = ONE_STONK;
        uint256 _totalPrice = _currentPrice;
        uint256 _newPrice = _currentPrice;
        
        while(true) {

            if(_stonksToBuy >= _totalStonks) {
                break;
            } 

            _newPrice += COST_PER_STONK;
            _totalPrice += _newPrice;
            _stonksToBuy += ONE_STONK;
        }

        uint256 _totalFee = SafeMath.div((_totalPrice * platformFeePercentage), BASE_PERCENTAGE);
        uint256 _grandTotal = (_totalPrice + _totalFee);

        return (_totalStonks, _totalPrice, _totalFee, _grandTotal, _newPrice);
    }

    function buyStonks(
        bytes32 _memeId,
        uint256 _stonks
    ) public {
        (uint256 _totalStonks, 
        uint256 _totalPrice, 
        uint256 _totalFee, 
        uint256 _grandTotal, 
        uint256 _newPrice) = getStonkBuyPrices(_memeId, _stonks);

        // Collect collateral + platform fee
        require(collateralToken.transferFrom(msg.sender, address(this), _grandTotal), "Funds transfer failed!");

        // Transfer platform fee to the platform fee wallet
        require(collateralToken.transfer(platformFeeAddress, _totalFee), "Fee transfer failed");

        // Mint stonks
        uint256 _tokenId = memes[_memeId].stonkTokenId;
        _mint(msg.sender, _tokenId, _totalStonks, '');
        //safeTransferFrom(address(this), msg.sender, _tokenId, _totalStonks, '');

        _updateStonkTokenPrice(_memeId, _newPrice);  

        emit StonkBuy(msg.sender, _memeId, _totalStonks, _totalPrice, _totalFee, _grandTotal);
    }
   
    function getSingleStonkSellPrice(
        bytes32 _memeId
    ) public view returns (uint256) {
        require(isCreated(_memeId), "Meme doesn't exist!");

        return memes[_memeId].stonkTokenPrice;
    }

    function getStonkSellPrices(
        bytes32 _memeId,
        uint256 _stonks
    ) public view returns (uint256, uint256, uint256, uint256, uint256) {
        require(_stonks >= ONE_STONK, "Need quantity of one stonk or greater");
        
        uint256 _totalStonks = Math.ceilDiv(_stonks, ONE_STONK) * ONE_STONK;

        uint256 _currentPrice = getSingleStonkSellPrice(_memeId);

        uint256 _stonksToSell = 0;
        uint256 _totalPrice = _currentPrice;
        uint256 _newPrice = _currentPrice;
        
        while(true) {

            if(_stonksToSell >= _totalStonks || _totalPrice <= 0) {
                break;
            }

            _newPrice -= COST_PER_STONK;
            _totalPrice += _newPrice;
            _stonksToSell += ONE_STONK; 
        }

        uint256 _totalFee = SafeMath.div((_totalPrice * platformFeePercentage), BASE_PERCENTAGE);
        uint256 _grandTotal = (_totalPrice - _totalFee);

        return (_totalStonks, _totalPrice, _totalFee, _grandTotal, _newPrice);
    }

    function sellStonks(
        bytes32 _memeId, 
        uint256 _stonks
    ) public {
        (uint256 _totalStonks, 
        uint256 _totalPrice, 
        uint256 _totalFee, 
        uint256 _grandTotal, 
        uint256 _newPrice) = getStonkSellPrices(_memeId, _stonks);

        // Collect platform fee
        require(collateralToken.transfer(platformFeeAddress, _totalFee), "Fee transfer failed");

        // Return collateral minus platform fees
        require(collateralToken.transfer(msg.sender, _grandTotal), "Funds transfer failed");

        // Burn stonks
        uint256 _tokenId = memes[_memeId].stonkTokenId;
        //safeTransferFrom(msg.sender, address(this), _tokenId, _totalStonks, '');
        _burn(msg.sender, _tokenId, _totalStonks);

        _updateStonkTokenPrice(_memeId, _newPrice);

        emit StonkSell(msg.sender, _memeId, _totalStonks, _totalPrice, _totalFee, _grandTotal);
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

    function isCreated(
        bytes32 _memeId
    ) public view returns (bool) {
        return memes[_memeId].stonkTokenId > 0;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
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
        return 0x00;
    }
    

    /*///////////////////////////////////////////////////////////////////
    PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////*/

    function _updateStonkTokenPrice(
        bytes32 _memeId, 
        uint256 _newPrice
    ) private {
        memes[_memeId].stonkTokenPrice = _newPrice;

        emit StonkPriceUpdated(_memeId, _newPrice);
    }

    function _getAllowance() private view returns(uint256){
        return collateralToken.allowance(msg.sender, address(this));
    }
}