// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MemePoolLiquidity {

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // // create the pair if it doesn't exist yet
        // if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
        //     IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        // }
        // (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        // if (reserveA == 0 && reserveB == 0) {
        //     (amountA, amountB) = (amountADesired, amountBDesired);
        // } else {
        //     uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
        //     if (amountBOptimal <= amountBDesired) {
        //         require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
        //         (amountA, amountB) = (amountADesired, amountBOptimal);
        //     } else {
        //         uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
        //         assert(amountAOptimal <= amountADesired);
        //         require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        //         (amountA, amountB) = (amountAOptimal, amountBDesired);
        //     }
        // }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        // address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        // TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        // TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        // liquidity = IUniswapV2Pair(pair).mint(to);
    }
    

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual ensure(deadline) returns (uint amountA, uint amountB) {
        // address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        // IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        // (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        // (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        // (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'INSUFFICIENT_B_AMOUNT');
    }
}