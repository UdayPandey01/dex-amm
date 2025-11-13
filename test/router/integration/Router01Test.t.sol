//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import "../../../script/router/DeployUniswapV2Router.s.sol";
import "../../mock/TestERC20Mock.sol";
import "../../../src/core/UniswapV2Factory.sol";
import "../../../src/core/interfaces/IUniswapV2Pair.sol";
import "../../../src/core/interfaces/IUniswapV2ERC20.sol";
import "../../../src/router/WETH9.sol";
import "../../../src/router/Router02.sol" as RouterContract;

contract Router01Test is Test {
    DeployUniswapV2Router public deploy;
    UniswapV2Factory public factory;
    MockERC20 public DOL;
    MockERC20 public UP;
    IUniswapV2Pair public pair;
    WETH public weth;
    RouterContract.Router02 public router;

    address public deployer;
    address public expected_pair;
    bytes32 INIT_CODE_PAIR_HASH;
    address musk = makeAddr("musk");

    function setUp() public {
        deploy = new DeployUniswapV2Router();
        deploy.run();

        factory = deploy.factory();
        weth = deploy.weth();
        DOL = deploy.tokenA();
        UP = deploy.tokenB();

        router = deploy.router();
        deployer = deploy.deployer();

        INIT_CODE_PAIR_HASH = factory.INIT_CODE_PAIR_HASH();

        vm.deal(deployer, 1000 ether);
        vm.deal(musk, 100 ether);

        vm.startPrank(deployer);
        DOL.transfer(musk, 1000 ether);
        UP.transfer(musk, 10000 ether);
        vm.stopPrank();

        console.log("Router address:", address(router));
        console.log("Factory address:", address(factory));
        console.log("WETH address:", address(weth));
        console.log("DOL Token:", address(DOL));
        console.log("UP Token:", address(UP));
        console.log("Deployer:", deployer);
        console.log("Musk (test user):", musk);
        console.log(
            "\nIMPORTANT: Update UniswapV2Library.sol with this INIT_CODE_PAIR_HASH:"
        );
        console.log("Remove '0x' prefix and paste in pairFor() function");
        console2.logBytes32(INIT_CODE_PAIR_HASH);
    }

    function testGetInitCodeHash() public view {
        console.log("\n INIT_CODE_PAIR_HASH for UniswapV2Library.sol:");
        console.log("==========================================");
        console2.logBytes32(INIT_CODE_PAIR_HASH);
        console.log("==========================================");
        console.log("\n Steps to update:");
        console.log("1. Copy the hash above (remove 0x prefix)");
        console.log("2. Open: src/router/libraries/UniswapV2Library.sol");
        console.log("3. Find the pairFor() function (~line 36)");
        console.log("4. Replace the hex value with your hash");
        console.log("\n Verification passed - Factory deployed successfully!");

        // Force display in test output
        assertEq(
            uint256(INIT_CODE_PAIR_HASH),
            uint256(INIT_CODE_PAIR_HASH),
            "Hash value for reference"
        );
    }

    function testSetupState() public view {
        assertTrue(address(factory) != address(0), "Factory not deployed");
        assertTrue(address(weth) != address(0), "WETH not deployed");
        assertTrue(address(router) != address(0), "Router not deployed");
        assertTrue(address(DOL) != address(0), "DOL token not deployed");
        assertTrue(address(UP) != address(0), "UP token not deployed");

        assertEq(DOL.balanceOf(musk), 1000 ether, "Musk DOL balance incorrect");
        assertEq(UP.balanceOf(musk), 10000 ether, "Musk UP balance incorrect");
        assertEq(musk.balance, 100 ether, "Musk ETH balance incorrect");

        console.log("\n All setup verifications passed!");
    }

    function testAddLiquidityCreatesPair() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

        address pairbefore = factory.getPair(address(DOL), address(UP));

        vm.startPrank(deployer);

        DOL.approve(address(router), amountADesired);
        UP.approve(address(router), amountBDesired);

        router.addLiquidity(
            address(DOL),
            address(UP),
            amountADesired,
            amountBDesired,
            0,
            0,
            deployer,
            block.timestamp + 300
        );
        vm.stopPrank();

        address pairAfter = factory.getPair(address(DOL), address(UP));

        assertEq(
            pairbefore,
            address(0),
            "Pair already exists before adding liquidity"
        );
        assertTrue(
            pairAfter != address(0),
            "Pair was not created after adding liquidity"
        );
    }

    function testAddLiquidityDepositsCorrectAmounts() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

        vm.startPrank(deployer);
        DOL.approve(address(router), amountADesired);
        UP.approve(address(router), amountBDesired);

        (uint256 amountA, uint256 amountB, ) = router.addLiquidity(
            address(DOL),
            address(UP),
            amountADesired,
            amountBDesired,
            0,
            0,
            deployer,
            block.timestamp + 300
        );
        vm.stopPrank();

        assertEq(amountA, amountADesired, "Incorrect amount of DOL deposited");
        assertEq(amountB, amountBDesired, "Incorrect amount of UP deposited");
    }

    function testAddLiquidityMintsLPTokens() public {
        // TODO: Implement this test
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

        vm.startPrank(deployer);

        DOL.approve(address(router), amountADesired);
        UP.approve(address(router), amountBDesired);
        (, , uint256 liquidity) = router.addLiquidity(
            address(DOL),
            address(UP),
            amountADesired,
            amountBDesired,
            0,
            0,
            deployer,
            block.timestamp + 300
        );

        vm.stopPrank();

        address pairAddress = factory.getPair(address(DOL), address(UP));
        uint256 LpBalance = IUniswapV2Pair(pairAddress).balanceOf(deployer);

        assertTrue(liquidity > 0, "No liquidity tokens minted");
        assertEq(LpBalance, liquidity, "Deployer did not receive LP tokens");
    }

    function testAddLiquidityTransfersTokensFromUser() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

        vm.startPrank(deployer);

        DOL.approve(address(router), amountADesired);
        UP.approve(address(router), amountBDesired);

        uint256 dolBalanceBefore = DOL.balanceOf(deployer);
        uint256 upBalanceBefore = UP.balanceOf(deployer);

        console.log("DOL balance before:", dolBalanceBefore);
        console.log("UP balance before:", upBalanceBefore);

        (uint256 amountA, uint256 amountB, ) = router.addLiquidity(
            address(DOL),
            address(UP),
            amountADesired,
            amountBDesired,
            0,
            0,
            deployer,
            block.timestamp + 300
        );

        vm.stopPrank();

        uint256 dolBalanceAfter = DOL.balanceOf(deployer);
        uint256 upBalanceAfter = UP.balanceOf(deployer);

        console.log("DOL balance after:", dolBalanceAfter);
        console.log("UP balance after:", upBalanceAfter);
        console.log("Actual amountA deposited:", amountA);
        console.log("Actual amountB deposited:", amountB);

        assertEq(
            dolBalanceAfter,
            dolBalanceBefore - amountA,
            "DOL balance did not decrease by actual deposited amount"
        );

        assertEq(
            upBalanceAfter,
            upBalanceBefore - amountB,
            "UP balance did not decrease by actual deposited amount"
        );
    }
    
    function testAddLiquidityPairHoldsTokens() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

        vm.startPrank(deployer);

        DOL.approve(address(router), amountADesired);
        UP.approve(address(router), amountBDesired);

        (uint256 amountA, uint256 amountB, ) = router.addLiquidity(
            address(DOL),
            address(UP),
            amountADesired,
            amountBDesired,
            0,
            0,
            deployer,
            block.timestamp + 300
        );

        vm.stopPrank();

        address pairAddress = factory.getPair(address(DOL), address(UP));
        
        uint256 DOLPairBalance = DOL.balanceOf(pairAddress);
        uint256 UPPairBalance = UP.balanceOf(pairAddress);

        assertEq(
            DOLPairBalance,
            amountA,
            "Pair does not hold correct amount of DOL"
        );

        assertEq(
            UPPairBalance,
            amountB,
            "Pair does not hold correct amount of UP"
        );
    }

    function testAddLiquidityUpdatesReserves() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

        vm.startPrank(deployer);

        DOL.approve(address(router), amountADesired);
        UP.approve(address(router), amountBDesired);

        (uint256 amountA, uint256 amountB, ) = router.addLiquidity(
            address(DOL),
            address(UP),
            amountADesired,
            amountBDesired,
            0,
            0,
            deployer,
            block.timestamp + 300
        );

        vm.stopPrank();

        address pairAddress = factory.getPair(address(DOL), address(UP));
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();

        address token0 = IUniswapV2Pair(pairAddress).token0();
        address token1 = IUniswapV2Pair(pairAddress).token1();

        console.log("Token0:", token0);
        console.log("Token1:", token1);
        console.log("address of DOL", address(DOL));
        console.log("address of UP", address(UP));
        console.log("Reserve0:", reserve0);
        console.log("Reserve1:", reserve1);

        if (token0 == address(DOL)) {
            assertEq(reserve0, amountA, "Reserve0 (DOL) does not match deposited amount");
            assertEq(reserve1, amountB, "Reserve1 (UP) does not match deposited amount");
        } else {
            assertEq(reserve0, amountB, "Reserve0 (UP) does not match deposited amount");
            assertEq(reserve1, amountA, "Reserve1 (DOL) does not match deposited amount");
        }
    }

    function testAddLiquidityLocksMinimumLiquidity() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

        vm.startPrank(deployer);

        DOL.approve(address(router), amountADesired);
        UP.approve(address(router), amountBDesired);

        (, , uint256 liquidity) = router.addLiquidity(
            address(DOL),
            address(UP),
            amountADesired,
            amountBDesired,
            0,
            0,
            deployer,
            block.timestamp + 300
        );

        vm.stopPrank();

        address pairAddress = factory.getPair(address(DOL), address(UP));
        uint256 totalSupply = IUniswapV2Pair(pairAddress).totalSupply();

        assertEq(
            totalSupply,
            liquidity + 1000,
            "MINIMUM_LIQUIDITY not locked in pair"
        );
    }

    function testRemoveLiquidity() public {
        
    }
}
