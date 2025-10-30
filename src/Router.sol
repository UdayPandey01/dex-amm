//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Pair.sol";
import "./Library.sol";

contract Router {
    address public factory;

    constructor(address _factory) {
        factory = _factory;
    }

    function _getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) external view returns (uint256 reserveA, uint256 reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1) = Pair(Library.pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // function _swap(uint[] memory amounts, address[] memory path, address _to) private {
    //     for (uint i; i < path.length - 1; i++) {
    //         (address input, address output) = (path[i], path[i + 1]);
    //         (address token0,) = UniswapV2Library.sortTokens(input, output);
    //         uint amountOut = amounts[i + 1];
    //         (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
    //         address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
    //         Pair(pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
    //     }
    // }

    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] calldata path
    ) external returns (uint256[] memory amounts) {
        require(path.length >= 2, "Invalid path");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for(uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = this.getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = this.getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        amounts = getAmountsOut(amountIn, path);

        require(amounts[amounts.length - 1] >= amountOutMin, "Insufficient output");

        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (uint amount0Out, uint amount1Out) = input < output
                ? (uint(0), amounts[i + 1])
                : (amounts[i + 1], uint(0));

            address nextTo = i < path.length - 2
                ? Library.pairFor(factory, output, path[i + 2])
                : to;

            Pair(Library.pairFor(factory, input, output)).swap(
                amount0Out,
                amount1Out,
                nextTo
            );
        }
    }

}
