// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract MeemERC20 is ERC20Capped, AccessControl {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    constructor()
        ERC20("Memera","MEEM")
        ERC20Capped(6900000000000 * (10 ** uint256(decimals())))
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(MODERATOR_ROLE, msg.sender);
    }

    modifier checkRole(
        bytes32 role,
        address account,
        string memory message
    ) {
        require(hasRole(role, account), message);
        _;
    }

    function mint(address _to, uint256 _amount)
        external
        checkRole(MINTER_ROLE, msg.sender, "Caller is not a minter")
    {
        super._mint(_to, _amount);
    }
}
