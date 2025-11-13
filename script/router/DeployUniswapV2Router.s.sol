// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/Console2.sol";
import "../../src/core/UniswapV2Factory.sol";
import "../../test/mock/TestERC20Mock.sol";
import "../../src/router/WETH9.sol";
import "../../src/router/Router02.sol" as Router;
import "../../src/router/libraries/UniswapV2Library.sol";

contract DeployUniswapV2Router is Script {
    error UnsupportedNetwork();

    WETH public weth;
    UniswapV2Factory public factory;

    MockERC20 public tokenA;
    MockERC20 public tokenB;
    Router.Router02 public router;

    address public deployer;
    uint256 public deployerPrivateKey;

    function run() external {
        uint256 chainId = block.chainid;

        if (chainId == 1) {
            console2.log("Deploying this on Ethereum Mainnet");
            deployerPrivateKey = vm.envUint("MAINNET_PRIVATE_KEY");
        } else if (chainId == 11155111) {
            console2.log("Deploying this on Sepolia Testnet");
            deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
        } else if (chainId == 31337) {
            console2.log("Deploying this on Localhost Anvil");
            deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
            console2.log("Using default Foundry test account");
        } else {
            revert UnsupportedNetwork();
        }

        deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        weth = new WETH();
        factory = new UniswapV2Factory(deployer);

        tokenA = new MockERC20("DollarToken", "DOL", 100000 ether);
        tokenB = new MockERC20("UPToken", "UP", 100000000 ether);

        router = new Router.Router02(address(factory), address(weth));

        vm.stopBroadcast();

        console2.log("WETH deployed at:", address(factory));
        console2.log("TokenA deployed at:", address(tokenA));
        console2.log("TokenB deployed at:", address(tokenB));

        console2.log("Deployer address:", deployer);
        console2.log("Router address:", address(router));
    }
}
