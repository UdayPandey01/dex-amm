//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/interfaces/IUniswapV2Factory.sol";
import "./interfaces/IRouter01.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/UniswapV2Library.sol";

contract Router01 is IRouter01 {
    address public override factory;
    address public override WETH;

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) private returns (uint256 amountA, uint256 amountB) {
        if(IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }

        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);

        if(reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBoptional = UniswapV2Library.quote(amountADesired, reserveA, reserveB);

            if(amountBoptional <= amountBDesired) {
                require(amountBoptional > amountBMin, "Router: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBoptional);
            } else {
                uint256 amountAoptional = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                require(amountAoptional <= amountADesired, "Router: INSUFFICIENT_A_AMOUNT");
                require(amountAoptional > amountAMin, "Router: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAoptional, amountBDesired);
            }
        }
    }
}