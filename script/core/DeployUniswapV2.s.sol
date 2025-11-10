//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/Console2.sol";
import "../../src/core/UniswapV2Factory.sol";
import "../../test/mock/TestERC20Mock.sol";

contract DeployUniswapV2 is Script {
    error UnsupportedNetwork();

    UniswapV2Factory public factory;
    MockERC20 public tokenA;
    MockERC20 public tokenB;

    address public deployer;
    address public pair;

    function run() external {
        uint256 chainId = block.chainid;
        uint256 deployerPrivateKey;

        if (chainId == 1) {
            console2.log("Deploying this on Ethereum Mainnet");
            deployerPrivateKey = vm.envUint("MAINNET_PRIVATE_KEY");
        } else if (chainId == 11155111) {
            console2.log("Deploying this on Sepolia Testnet");
            deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
        } else if (chainId == 31337) {
            console2.log("Deploying this on Localhost Anvil");
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            revert UnsupportedNetwork();
        }

        deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        factory = new UniswapV2Factory(deployer);

        tokenA = new MockERC20("EthereumTokenA", "ETH", 100000 ether);
        tokenB = new MockERC20("DollarTokenB", "USD", 100000000 ether);

        pair = factory.createPair(address(tokenA), address(tokenB));

        console2.log("Factory deployed at:", address(factory));
        console2.log("TokenA deployed at:", address(tokenA));
        console2.log("TokenB deployed at:", address(tokenB));
        console2.log("Pair deployed at:", pair);

        vm.stopBroadcast();
    }
}
