//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Pair {
    uint112 private reserve0 = 1000;
    uint112 private reserve1 = 2000;

    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function swap(uint amount0Out, uint amount1Out, address _to) external {

    }
}