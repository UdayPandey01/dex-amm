// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import "../src/core/UniswapV2Pair.sol";

contract GetInitCodeHash is Script {
    function run() public pure {
        bytes32 hash = keccak256(
            abi.encodePacked(type(UniswapV2Pair).creationCode)
        );
        console2.log("\n=== INIT_CODE_PAIR_HASH ===");
        console2.logBytes32(hash);
        console2.log("\nUpdate this hash in:");
        console2.log("- src/router/libraries/UniswapV2Library.sol (line ~38)");
    }
}
