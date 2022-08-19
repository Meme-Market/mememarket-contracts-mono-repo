// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MemeERC20 is ERC20 {
    constructor() ERC20("Meme Token", "MEME") {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals()))); // minting 1,000,000 tokens
    }

    function getTokens(address _TokenContractAddress, address recipient, uint256 token_count) public {
        IERC20 _token = IERC20(_TokenContractAddress); // token contract address
        // in wei from address that has deployed token contract
        _token.transferFrom(address(this), payable(recipient), token_count);
    }
}
