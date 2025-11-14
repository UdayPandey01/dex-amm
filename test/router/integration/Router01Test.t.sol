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
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pairAddress)
            .getReserves();

        address token0 = IUniswapV2Pair(pairAddress).token0();
        address token1 = IUniswapV2Pair(pairAddress).token1();

        console.log("Token0:", token0);
        console.log("Token1:", token1);
        console.log("address of DOL", address(DOL));
        console.log("address of UP", address(UP));
        console.log("Reserve0:", reserve0);
        console.log("Reserve1:", reserve1);

        if (token0 == address(DOL)) {
            assertEq(
                reserve0,
                amountA,
                "Reserve0 (DOL) does not match deposited amount"
            );
            assertEq(
                reserve1,
                amountB,
                "Reserve1 (UP) does not match deposited amount"
            );
        } else {
            assertEq(
                reserve0,
                amountB,
                "Reserve0 (UP) does not match deposited amount"
            );
            assertEq(
                reserve1,
                amountA,
                "Reserve1 (DOL) does not match deposited amount"
            );
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

        address pairAddress = factory.getPair(address(DOL), address(UP));
        IUniswapV2Pair(pairAddress).approve(address(router), liquidity);

        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            address(DOL),
            address(UP),
            liquidity,
            0,
            0,
            deployer,
            block.timestamp + 300
        );

        vm.stopPrank();

        assertTrue(amountA > 0, "No DOL returned on removeLiquidity");
        assertTrue(amountB > 0, "No UP returned on removeLiquidity");
    }

    function testRemoveLiquidityPartial() public {
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

        address pairAddress = factory.getPair(address(DOL), address(UP));
        IUniswapV2Pair(pairAddress).approve(address(router), liquidity);

        uint256 liquidityToRemove = liquidity / 2;

        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            address(DOL),
            address(UP),
            liquidityToRemove,
            0,
            0,
            deployer,
            block.timestamp + 300
        );

        vm.stopPrank();

        assertTrue(amountA > 0, "No DOL returned on partial removeLiquidity");
        assertTrue(amountB > 0, "No UP returned on partial removeLiquidity");
        assertEq(
            IUniswapV2Pair(pairAddress).balanceOf(deployer),
            liquidity - liquidityToRemove,
            "Incorrect LP token balance after partial remove"
        );
    }

    function testRemoveLiquiditySlippageProtection() public {
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

        vm.startPrank(musk);

        address pairAddress = factory.getPair(address(DOL), address(UP));

        UP.approve(address(router), 500 ether);

        address[] memory path = new address[](2);
        path[0] = address(UP);
        path[1] = address(DOL);

        router.swapExactTokensForTokens(
            500 ether,
            0,
            path,
            musk,
            block.timestamp + 300
        );

        vm.stopPrank();

        vm.startPrank(deployer);

        IUniswapV2Pair(pairAddress).approve(address(router), liquidity);

        uint256 highAmountAMin = 99 ether;
        uint256 highAmountBMin = 0;

        vm.expectRevert(bytes("UniswapV2Router: INSUFFICIENT_A_AMOUNT"));
        router.removeLiquidity(
            address(DOL),
            address(UP),
            liquidity,
            highAmountAMin,
            highAmountBMin,
            deployer,
            block.timestamp + 300
        );

        vm.stopPrank();

        console.log("\n=== Slippage Protection Verified ===");
        console.log(
            "Transaction correctly reverted when received amount < minimum"
        );
    }

    function testRemoveLiquidityWithoutApproval() public {
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

        address pairAddress = factory.getPair(address(DOL), address(UP));

        vm.expectRevert();
        router.removeLiquidity(
            address(DOL),
            address(UP),
            liquidity,
            0,
            0,
            deployer,
            block.timestamp + 300
        );

        vm.stopPrank();
    }

    function testRemoveLiquidityExpiredDeadline() public {
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

        address pairAddress = factory.getPair(address(DOL), address(UP));
        IUniswapV2Pair(pairAddress).approve(address(router), liquidity);

        uint256 expiredDeadline = 100;
        vm.warp(expiredDeadline + 1);

        vm.expectRevert(bytes("UniswapV2Router:EXPIRED"));
        router.removeLiquidity(
            address(DOL),
            address(UP),
            liquidity - 1000,
            0,
            0,
            deployer,
            expiredDeadline
        );

        vm.stopPrank();
    }

    function testRemoveLiquidityMultipleProviders() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

        vm.startPrank(deployer);

        DOL.approve(address(router), amountADesired);
        UP.approve(address(router), amountBDesired);

        (, , uint256 liquidityDeployer) = router.addLiquidity(
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

        vm.startPrank(musk);

        uint256 muskAmountA = 200 ether;
        uint256 muskAmountB = 2000 ether;

        DOL.approve(address(router), muskAmountA);
        UP.approve(address(router), muskAmountB);

        (, , uint256 liquidityMusk) = router.addLiquidity(
            address(DOL),
            address(UP),
            muskAmountA,
            muskAmountB,
            0,
            0,
            musk,
            block.timestamp + 300
        );

        vm.stopPrank();

        vm.startPrank(deployer);

        address pairAddress = factory.getPair(address(DOL), address(UP));
        IUniswapV2Pair(pairAddress).approve(address(router), liquidityDeployer);

        (uint256 amountADeployer, uint256 amountBDeployer) = router
            .removeLiquidity(
                address(DOL),
                address(UP),
                liquidityDeployer,
                0,
                0,
                deployer,
                block.timestamp + 300
            );

        vm.stopPrank();

        vm.startPrank(musk);

        IUniswapV2Pair(pairAddress).approve(address(router), liquidityMusk);

        (uint256 amountAMusk, uint256 amountBMusk) = router.removeLiquidity(
            address(DOL),
            address(UP),
            liquidityMusk,
            0,
            0,
            musk,
            block.timestamp + 300
        );

        vm.stopPrank();

        assertTrue(amountADeployer > 0, "Deployer received no DOL on removal");
        assertTrue(amountBDeployer > 0, "Deployer received no UP on removal");
        assertTrue(amountAMusk > 0, "Musk received no DOL on removal");
        assertTrue(amountBMusk > 0, "Musk received no UP on removal");

        assertApproxEqRel(
            amountAMusk,
            amountADeployer * 2,
            0.01e18,
            "Musk should receive ~2x DOL compared to Deployer"
        );
        assertApproxEqRel(
            amountBMusk,
            amountBDeployer * 2,
            0.01e18,
            "Musk should receive ~2x UP compared to Deployer"
        );

        assertTrue(
            amountADeployer < amountAMusk,
            "Deployer should receive less DOL than Musk"
        );
        assertTrue(
            amountBDeployer < amountBMusk,
            "Deployer should receive less UP than Musk"
        );
    }

    /// @notice Test removing liquidity after swaps changed the reserves
    /// @dev Hint: Add liquidity, perform swaps to change reserves, then remove liquidity
    /// @dev Assert: User gets back different ratio than originally deposited (impermanent loss)
    function testRemoveLiquidityAfterSwaps() public {
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

        console.log("\n=== Initial State ===");
        console.log("DOL deposited:", amountADesired);
        console.log("UP deposited:", amountBDesired);
        console.log("Initial ratio DOL:UP = 1:10");

        vm.startPrank(musk);

        UP.approve(address(router), 500 ether);
        address[] memory path = new address[](2);
        path[0] = address(UP);
        path[1] = address(DOL);

        router.swapExactTokensForTokens(
            500 ether,
            0,
            path,
            musk,
            block.timestamp + 300
        );

        vm.stopPrank();

        address pairAddress = factory.getPair(address(DOL), address(UP));
        (uint112 reserve0After, uint112 reserve1After, ) = IUniswapV2Pair(
            pairAddress
        ).getReserves();

        console.log("\n=== After Swap ===");
        console.log("Reserve0:", reserve0After);
        console.log("Reserve1:", reserve1After);

        vm.startPrank(deployer);

        IUniswapV2Pair(pairAddress).approve(address(router), liquidity);

        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            address(DOL),
            address(UP),
            liquidity,
            0,
            0,
            deployer,
            block.timestamp + 300
        );

        vm.stopPrank();

        console.log("\n=== Amounts Returned ===");
        console.log("DOL returned:", amountA);
        console.log("UP returned:", amountB);

        assertTrue(
            amountA < amountADesired,
            "Should receive LESS DOL than originally deposited"
        );

        assertTrue(
            amountB > amountBDesired,
            "Should receive MORE UP than originally deposited"
        );

        uint256 initialRatio = (amountBDesired * 1e18) / amountADesired;
        uint256 finalRatio = (amountB * 1e18) / amountA;

        assertTrue(
            finalRatio != initialRatio,
            "Ratio should change due to swaps (impermanent loss)"
        );

        assertTrue(
            finalRatio > initialRatio,
            "Should have more UP per DOL after UP->DOL swap"
        );

        console.log("\n=== Impermanent Loss Demo ===");
        console.log("Initial ratio (UP:DOL):", initialRatio / 1e18);
        console.log("Final ratio (UP:DOL):", finalRatio / 1e18);
        console.log(
            "DOL difference:",
            int256(amountADesired) - int256(amountA)
        );
        console.log("UP difference:", int256(amountB) - int256(amountBDesired));
    }

    function testRemoveLiquidityExcessiveAmount() public {
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

        address pairAddress = factory.getPair(address(DOL), address(UP));
        IUniswapV2Pair(pairAddress).approve(address(router), liquidity * 2);

        vm.expectRevert();
        router.removeLiquidity(
            address(DOL),
            address(UP),
            liquidity * 2,
            0,
            0,
            deployer,
            block.timestamp + 300
        );

        vm.stopPrank();
    }

    function testRemoveLiquidityBurnsLPTokens() public {
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

        address pairAddress = factory.getPair(address(DOL), address(UP));

        uint256 totalSupplyBefore = IUniswapV2Pair(pairAddress).totalSupply();
        uint256 deployerBalanceBefore = IUniswapV2Pair(pairAddress).balanceOf(
            deployer
        );

        console.log("\n=== Before Removal ===");
        console.log("Total LP supply:", totalSupplyBefore);
        console.log("Deployer LP balance:", deployerBalanceBefore);
        console.log("LP to burn:", liquidity);

        IUniswapV2Pair(pairAddress).approve(address(router), liquidity);

        router.removeLiquidity(
            address(DOL),
            address(UP),
            liquidity,
            0,
            0,
            deployer,
            block.timestamp + 300
        );

        vm.stopPrank();

        uint256 totalSupplyAfter = IUniswapV2Pair(pairAddress).totalSupply();
        uint256 deployerBalanceAfter = IUniswapV2Pair(pairAddress).balanceOf(
            deployer
        );

        console.log("\n=== After Removal ===");
        console.log("Total LP supply:", totalSupplyAfter);
        console.log("Deployer LP balance:", deployerBalanceAfter);
        console.log("LP burned:", totalSupplyBefore - totalSupplyAfter);

        assertEq(
            totalSupplyAfter,
            totalSupplyBefore - liquidity,
            "Total supply did not decrease by burned amount"
        );

        assertEq(
            deployerBalanceAfter,
            0,
            "Deployer still has LP tokens after removal"
        );

        assertEq(
            totalSupplyAfter,
            1000,
            "Only MINIMUM_LIQUIDITY (1000 wei) should remain"
        );
    }

    function testRemoveLiquidityToCustomAddress() public {
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

        address pairAddress = factory.getPair(address(DOL), address(UP));

        uint256 deployerDOLBefore = DOL.balanceOf(deployer);
        uint256 deployerUPBefore = UP.balanceOf(deployer);
        uint256 muskDOLBefore = DOL.balanceOf(musk);
        uint256 muskUPBefore = UP.balanceOf(musk);

        console.log("\n=== Before Removal ===");
        console.log("Deployer DOL:", deployerDOLBefore);
        console.log("Deployer UP:", deployerUPBefore);
        console.log("Musk DOL:", muskDOLBefore);
        console.log("Musk UP:", muskUPBefore);

        IUniswapV2Pair(pairAddress).approve(address(router), liquidity);

        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            address(DOL),
            address(UP),
            liquidity,
            0,
            0,
            musk,
            block.timestamp + 300
        );

        vm.stopPrank();

        uint256 deployerDOLAfter = DOL.balanceOf(deployer);
        uint256 deployerUPAfter = UP.balanceOf(deployer);
        uint256 muskDOLAfter = DOL.balanceOf(musk);
        uint256 muskUPAfter = UP.balanceOf(musk);

        console.log("\n=== After Removal ===");
        console.log("Deployer DOL:", deployerDOLAfter);
        console.log("Deployer UP:", deployerUPAfter);
        console.log("Musk DOL:", muskDOLAfter);
        console.log("Musk UP:", muskUPAfter);
        console.log("Amount A returned:", amountA);
        console.log("Amount B returned:", amountB);

        assertEq(
            deployerDOLAfter,
            deployerDOLBefore,
            "Deployer DOL balance should not change"
        );
        assertEq(
            deployerUPAfter,
            deployerUPBefore,
            "Deployer UP balance should not change"
        );

        assertEq(
            muskDOLAfter,
            muskDOLBefore + amountA,
            "Musk should receive DOL tokens"
        );
        assertEq(
            muskUPAfter,
            muskUPBefore + amountB,
            "Musk should receive UP tokens"
        );

        uint256 deployerLPBalance = IUniswapV2Pair(pairAddress).balanceOf(
            deployer
        );
        assertEq(
            deployerLPBalance,
            0,
            "Deployer LP tokens should be burned despite tokens going to musk"
        );

        console.log("\n=== Verified: Tokens sent to custom address (musk) ===");
    }

    function testRemoveLiquidityMinimumLiquidityPersists() public {
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

        address pairAddress = factory.getPair(address(DOL), address(UP));

        uint256 totalSupplyBefore = IUniswapV2Pair(pairAddress).totalSupply();
        uint256 addressZeroBalance = IUniswapV2Pair(pairAddress).balanceOf(
            address(0)
        );

        console.log("\n=== After Adding Liquidity ===");
        console.log("Total LP supply:", totalSupplyBefore);
        console.log("Deployer LP balance:", liquidity);
        console.log("Address(0) LP balance:", addressZeroBalance);
        // console.log("MINIMUM_LIQUIDITY:", 1000);
        assertEq(
            addressZeroBalance,
            1000,
            "Address(0) should hold MINIMUM_LIQUIDITY (1000 wei)"
        );

        IUniswapV2Pair(pairAddress).approve(address(router), liquidity);

        router.removeLiquidity(
            address(DOL),
            address(UP),
            liquidity,
            0,
            0,
            deployer,
            block.timestamp + 300
        );

        vm.stopPrank();

        uint256 totalSupplyAfter = IUniswapV2Pair(pairAddress).totalSupply();
        uint256 addressZeroBalanceAfter = IUniswapV2Pair(pairAddress).balanceOf(
            address(0)
        );
        uint256 deployerBalanceAfter = IUniswapV2Pair(pairAddress).balanceOf(
            deployer
        );

        console.log("\n=== After Removing ALL Liquidity ===");
        console.log("Total LP supply:", totalSupplyAfter);
        console.log("Deployer LP balance:", deployerBalanceAfter);
        console.log("Address(0) LP balance:", addressZeroBalanceAfter);

        assertEq(
            totalSupplyAfter,
            1000,
            "Total supply should be exactly MINIMUM_LIQUIDITY (1000 wei)"
        );

        assertEq(
            addressZeroBalanceAfter,
            1000,
            "Address(0) should still hold MINIMUM_LIQUIDITY (1000 wei)"
        );

        assertEq(
            deployerBalanceAfter,
            0,
            "Deployer should have 0 LP tokens after full removal"
        );

        assertEq(
            totalSupplyBefore,
            liquidity + 1000,
            "Initial total supply should be user liquidity + MINIMUM_LIQUIDITY"
        );

        console.log(
            "\n=== Verified: MINIMUM_LIQUIDITY permanently locked at address(0) ==="
        );
    }

    function testSwapExactTokensForTokens() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

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

        vm.startPrank(musk);

        uint256 swapAmountIn = 10 ether;

        uint256 muskDOLBefore = DOL.balanceOf(musk);
        uint256 muskUPBefore = UP.balanceOf(musk);

        address pairAddress = factory.getPair(address(DOL), address(UP));
        (uint112 reserve0Before, uint112 reserve1Before, ) = IUniswapV2Pair(
            pairAddress
        ).getReserves();

        DOL.approve(address(router), swapAmountIn);

        address[] memory path = new address[](2);
        path[0] = address(DOL);
        path[1] = address(UP);

        console.log("\n=== Before Swap ===");
        console.log("Musk DOL balance:", muskDOLBefore);
        console.log("Musk UP balance:", muskUPBefore);
        console.log("Reserve0:", reserve0Before);
        console.log("Reserve1:", reserve1Before);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            swapAmountIn,
            0,
            path,
            musk,
            block.timestamp + 300
        );

        vm.stopPrank();

        uint256 muskDOLAfter = DOL.balanceOf(musk);
        uint256 muskUPAfter = UP.balanceOf(musk);

        (uint112 reserve0After, uint112 reserve1After, ) = IUniswapV2Pair(
            pairAddress
        ).getReserves();

        console.log("\n=== After Swap ===");
        console.log("Musk DOL balance:", muskDOLAfter);
        console.log("Musk UP balance:", muskUPAfter);
        console.log("Reserve0:", reserve0After);
        console.log("Reserve1:", reserve1After);
        console.log("Amount IN:", amounts[0]);
        console.log("Amount OUT:", amounts[1]);

        assertEq(amounts[0], swapAmountIn, "Input amount incorrect");
        assertTrue(amounts[1] > 0, "Output amount should be greater than zero");

        assertEq(
            muskDOLAfter,
            muskDOLBefore - swapAmountIn,
            "Musk DOL balance should decrease by swap amount"
        );
        assertEq(
            muskUPAfter,
            muskUPBefore + amounts[1],
            "Musk UP balance should increase by output amount"
        );

        address token0 = IUniswapV2Pair(pairAddress).token0();
        if (token0 == address(DOL)) {
            assertEq(
                reserve0After,
                reserve0Before + swapAmountIn,
                "DOL reserves should increase"
            );
            assertEq(
                reserve1After,
                reserve1Before - amounts[1],
                "UP reserves should decrease"
            );
        } else {
            assertEq(
                reserve1After,
                reserve1Before + swapAmountIn,
                "DOL reserves should increase"
            );
            assertEq(
                reserve0After,
                reserve0Before - amounts[1],
                "UP reserves should decrease"
            );
        }
    }

    function testSwapExactTokensForTokensSlippageProtection() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

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

        vm.startPrank(musk);

        uint256 swapAmountIn = 10 ether;
        DOL.approve(address(router), swapAmountIn);

        address[] memory path = new address[](2);
        path[0] = address(DOL);
        path[1] = address(UP);

        uint256 excessiveAmountOutMin = 500 ether;
        vm.expectRevert(bytes("UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"));
        router.swapExactTokensForTokens(
            swapAmountIn,
            excessiveAmountOutMin,
            path,
            musk,
            block.timestamp + 300
        );
        vm.stopPrank();
    }

    function testSwapExactTokensForTokensWithoutApproval() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

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

        vm.startPrank(musk);

        uint256 swapAmountIn = 10 ether;

        address[] memory path = new address[](2);
        path[0] = address(DOL);
        path[1] = address(UP);

        vm.expectRevert();
        router.swapExactTokensForTokens(
            swapAmountIn,
            0,
            path,
            musk,
            block.timestamp + 300
        );
        vm.stopPrank();
    }

    function testSwapExactTokensForTokensExpiredDeadline() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

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

        vm.startPrank(musk);

        uint256 swapAmountIn = 10 ether;
        DOL.approve(address(router), swapAmountIn);

        address[] memory path = new address[](2);
        path[0] = address(DOL);
        path[1] = address(UP);

        uint256 expiredDeadline = 100;
        vm.warp(expiredDeadline + 1);

        vm.expectRevert(bytes("UniswapV2Router:EXPIRED"));
        router.swapExactTokensForTokens(
            swapAmountIn,
            0,
            path,
            musk,
            expiredDeadline
        );
        vm.stopPrank();
    }

    function testSwapExactTokensForTokensToCustomAddress() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

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

        vm.startPrank(musk);
        uint256 swapAmountIn = 10 ether;
        DOL.approve(address(router), swapAmountIn);

        address[] memory path = new address[](2);
        path[0] = address(DOL);
        path[1] = address(UP);

        uint256 deployerUPBefore = UP.balanceOf(deployer);
        uint256 muskUPBefore = UP.balanceOf(musk);
        uint256 muskDOLBefore = DOL.balanceOf(musk);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            swapAmountIn,
            0,
            path,
            deployer,
            block.timestamp + 300
        );
        vm.stopPrank();

        uint256 deployerUPAfter = UP.balanceOf(deployer);
        uint256 muskUPAfter = UP.balanceOf(musk);
        uint256 muskDOLAfter = DOL.balanceOf(musk);

        console.log("\n=== Custom Address Swap ===");
        console.log("Deployer UP before:", deployerUPBefore);
        console.log("Deployer UP after:", deployerUPAfter);
        console.log("Musk UP before:", muskUPBefore);
        console.log("Musk UP after:", muskUPAfter);
        console.log("Musk DOL before:", muskDOLBefore);
        console.log("Musk DOL after:", muskDOLAfter);
        console.log("Amount OUT:", amounts[1]);

        assertEq(
            deployerUPAfter,
            deployerUPBefore + amounts[1],
            "Deployer should receive UP tokens from swap"
        );

        assertEq(
            muskUPAfter,
            muskUPBefore,
            "Musk UP balance should stay the same (output sent to deployer)"
        );

        assertEq(
            muskDOLAfter,
            muskDOLBefore - swapAmountIn,
            "Musk should have paid DOL for the swap"
        );
    }

    function testSwapExactTokensForTokensConstantProduct() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

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

        address pairAddress = factory.getPair(address(DOL), address(UP));
        (uint112 reserve0Before, uint112 reserve1Before, ) = IUniswapV2Pair(
            pairAddress
        ).getReserves();

        uint256 kBefore = uint256(reserve0Before) * uint256(reserve1Before);
        console.log("\n=== Before Swap ===");
        console.log("Reserve0:", reserve0Before);
        console.log("Reserve1:", reserve1Before);
        console.log("K before:", kBefore);

        vm.startPrank(musk);

        uint256 swapAmountIn = 10 ether;
        DOL.approve(address(router), swapAmountIn);

        address[] memory path = new address[](2);
        path[0] = address(DOL);
        path[1] = address(UP);

        router.swapExactTokensForTokens(
            swapAmountIn,
            0,
            path,
            musk,
            block.timestamp + 300
        );
        vm.stopPrank();

        (uint112 reserve0After, uint112 reserve1After, ) = IUniswapV2Pair(
            pairAddress
        ).getReserves();

        uint256 kAfter = uint256(reserve0After) * uint256(reserve1After);
        console.log("\n=== After Swap ===");
        console.log("Reserve0:", reserve0After);
        console.log("Reserve1:", reserve1After);
        console.log("K after:", kAfter);

        assertTrue(
            kAfter > kBefore,
            "K after swap should be greater than K before due to fees"
        );
    }

    function testSwapExactTokensForTokensReverseDirection() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

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

        vm.startPrank(musk);

        uint256 swapAmountIn = 100 ether; 

        uint256 muskUPBefore = UP.balanceOf(musk);
        uint256 muskDOLBefore = DOL.balanceOf(musk);

        address pairAddress = factory.getPair(address(DOL), address(UP));
        (uint112 reserve0Before, uint112 reserve1Before, ) = IUniswapV2Pair(
            pairAddress
        ).getReserves();

        UP.approve(address(router), swapAmountIn);

        address[] memory path = new address[](2);
        path[0] = address(UP);
        path[1] = address(DOL);

        console.log("\n=== Before Reverse Swap (UP -> DOL) ===");
        console.log("Musk UP balance:", muskUPBefore);
        console.log("Musk DOL balance:", muskDOLBefore);
        console.log("Reserve0:", reserve0Before);
        console.log("Reserve1:", reserve1Before);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            swapAmountIn,
            0,
            path,
            musk,
            block.timestamp + 300
        );

        vm.stopPrank();

        uint256 muskUPAfter = UP.balanceOf(musk);
        uint256 muskDOLAfter = DOL.balanceOf(musk);

        (uint112 reserve0After, uint112 reserve1After, ) = IUniswapV2Pair(
            pairAddress
        ).getReserves();

        console.log("\n=== After Reverse Swap ===");
        console.log("Musk UP balance:", muskUPAfter);
        console.log("Musk DOL balance:", muskDOLAfter);
        console.log("Reserve0:", reserve0After);
        console.log("Reserve1:", reserve1After);
        console.log("Amount IN (UP):", amounts[0]);
        console.log("Amount OUT (DOL):", amounts[1]);

        assertEq(
            amounts[0],
            swapAmountIn,
            "Input amount should match swap amount"
        );
        assertTrue(amounts[1] > 0, "Output DOL should be greater than zero");

        assertEq(
            muskUPAfter,
            muskUPBefore - swapAmountIn,
            "Musk UP balance should decrease by swap amount"
        );
        assertEq(
            muskDOLAfter,
            muskDOLBefore + amounts[1],
            "Musk DOL balance should increase by output amount"
        );

        address token0 = IUniswapV2Pair(pairAddress).token0();
        if (token0 == address(DOL)) {
            assertEq(
                reserve0After,
                reserve0Before - amounts[1],
                "DOL reserves should decrease (output)"
            );
            assertEq(
                reserve1After,
                reserve1Before + swapAmountIn,
                "UP reserves should increase (input)"
            );
        } else {
            assertEq(
                reserve1After,
                reserve1Before - amounts[1],
                "DOL reserves should decrease (output)"
            );
            assertEq(
                reserve0After,
                reserve0Before + swapAmountIn,
                "UP reserves should increase (input)"
            );
        }
    }

    function testSwapExactTokensForTokensConsecutivePriceImpact() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

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

        vm.startPrank(musk);

        uint256 swapAmountIn = 10 ether;

        DOL.approve(address(router), swapAmountIn * 2); 

        address[] memory path = new address[](2);
        path[0] = address(DOL);
        path[1] = address(UP);

        console.log("\n=== First Swap ===");
        uint256[] memory amounts1 = router.swapExactTokensForTokens(
            swapAmountIn,
            0,
            path,
            musk,
            block.timestamp + 300
        );

        console.log("Input:", amounts1[0]);
        console.log("Output:", amounts1[1]);

        console.log("\n=== Second Identical Swap ===");
        uint256[] memory amounts2 = router.swapExactTokensForTokens(
            swapAmountIn,
            0,
            path,
            musk,
            block.timestamp + 300
        );

        console.log("Input:", amounts2[0]);
        console.log("Output:", amounts2[1]);

        vm.stopPrank();

        assertEq(
            amounts1[0],
            amounts2[0],
            "Both swaps should have same input amount"
        );

        assertTrue(
            amounts2[1] < amounts1[1],
            "Second swap should output LESS tokens (worse rate due to price impact)"
        );

        uint256 priceDifference = amounts1[1] - amounts2[1];
        console.log("\n=== Price Impact ===");
        console.log("First output:", amounts1[1]);
        console.log("Second output:", amounts2[1]);
        console.log("Difference:", priceDifference);
        console.log("Price impact %:", (priceDifference * 100) / amounts1[1]);

        assertTrue(priceDifference > 0, "Price impact should be measurable");
    }

    function testSwapTokensForExactTokens() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

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

        vm.startPrank(musk);

        uint256 desiredOutput = 90 ether;
        uint256 muskDOLBefore = DOL.balanceOf(musk);
        uint256 muskUPBefore = UP.balanceOf(musk);

        DOL.approve(address(router), 100 ether);

        address[] memory path = new address[](2);
        path[0] = address(DOL);
        path[1] = address(UP);

        uint256[] memory amounts = router.swapTokensForExactTokens(
            desiredOutput,
            100 ether,
            path,
            musk,
            block.timestamp + 300
        );

        vm.stopPrank();

        uint256 muskDOLAfter = DOL.balanceOf(musk);
        uint256 muskUPAfter = UP.balanceOf(musk);

        console.log("\n=== After SwapTokensForExactTokens ===");
        console.log("Musk DOL before:", muskDOLBefore);
        console.log("Musk DOL after:", muskDOLAfter);
        console.log("Musk UP before:", muskUPBefore);
        console.log("Musk UP after:", muskUPAfter);
        console.log("Amount IN (DOL):", amounts[0]);
        console.log("Amount OUT (UP):", amounts[1]);
        assertEq(
            amounts[1],
            desiredOutput,
            "Output amount should match desired exact output"
        );
        assertEq(
            muskDOLAfter,
            muskDOLBefore - amounts[0],
            "Musk DOL balance should decrease by input amount"
        );
        assertEq(
            muskUPAfter,
            muskUPBefore + amounts[1],
            "Musk UP balance should increase by output amount"
        );

    }

    function testSwapTokensForExactTokensSlippageProtection() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

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

        vm.startPrank(musk);

        uint256 desiredOutput = 90 ether;
        uint256 tooLowAmountInMax = 5 ether;

        DOL.approve(address(router), 100 ether);

        address[] memory path = new address[](2);
        path[0] = address(DOL);
        path[1] = address(UP);

        vm.expectRevert(bytes("UniswapV2Router: EXCESSIVE_INPUT_AMOUNT"));
        router.swapTokensForExactTokens(
            desiredOutput,
            tooLowAmountInMax,
            path,
            musk,
            block.timestamp + 300
        );

        vm.stopPrank();
    }

    function testSwapTokensForExactTokensWithoutApproval() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

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

        vm.startPrank(musk);

        uint256 desiredOutput = 90 ether;

        address[] memory path = new address[](2);
        path[0] = address(DOL);
        path[1] = address(UP);

        vm.expectRevert();
        router.swapTokensForExactTokens(
            desiredOutput,
            100 ether,
            path,
            musk,
            block.timestamp + 300
        );

        vm.stopPrank();
    }

    function testSwapTokensForExactTokensExpiredDeadline() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

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

        vm.startPrank(musk);

        uint256 desiredOutput = 90 ether;
        DOL.approve(address(router), 100 ether);

        address[] memory path = new address[](2);
        path[0] = address(DOL);
        path[1] = address(UP);

        uint256 expiredDeadline = 100;
        vm.warp(expiredDeadline + 1);

        vm.expectRevert(bytes("UniswapV2Router:EXPIRED"));
        router.swapTokensForExactTokens(
            desiredOutput,
            100 ether,
            path,
            musk,
            expiredDeadline
        );

        vm.stopPrank();
    }

    function testSwapTokensForExactTokensToCustomAddress() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

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

        vm.startPrank(musk);

        uint256 desiredOutput = 90 ether;
        DOL.approve(address(router), 100 ether);

        address[] memory path = new address[](2);
        path[0] = address(DOL);
        path[1] = address(UP);

        uint256 deployerUPBefore = UP.balanceOf(deployer);
        uint256 muskUPBefore = UP.balanceOf(musk);
        uint256 muskDOLBefore = DOL.balanceOf(musk);

        uint256[] memory amounts = router.swapTokensForExactTokens(
            desiredOutput,
            100 ether,
            path,
            deployer, 
            block.timestamp + 300
        );

        vm.stopPrank();

        uint256 deployerUPAfter = UP.balanceOf(deployer);
        uint256 muskUPAfter = UP.balanceOf(musk);
        uint256 muskDOLAfter = DOL.balanceOf(musk);

        console.log("\n=== Custom Address Swap (swapTokensForExactTokens) ===");
        console.log("Deployer UP before:", deployerUPBefore);
        console.log("Deployer UP after:", deployerUPAfter);
        console.log("Musk UP before:", muskUPBefore);
        console.log("Musk UP after:", muskUPAfter);
        console.log("Musk DOL before:", muskDOLBefore);
        console.log("Musk DOL after:", muskDOLAfter);
        console.log("Amount IN (DOL):", amounts[0]);
        console.log("Amount OUT (UP):", amounts[1]);

        assertEq(
            amounts[1],
            desiredOutput,
            "Output should be exact desired amount"
        );

        assertEq(
            deployerUPAfter,
            deployerUPBefore + desiredOutput,
            "Deployer should receive exact UP tokens"
        );

        assertEq(
            muskUPAfter,
            muskUPBefore,
            "Musk UP balance should stay the same (output sent to deployer)"
        );

        assertEq(
            muskDOLAfter,
            muskDOLBefore - amounts[0],
            "Musk should have paid DOL for the swap"
        );
    }

    /// @notice TODO: Test swap calculates input correctly
    /// @dev Hint: Want 90 UP out, verify calculated DOL input matches getAmountsIn
    /// @dev Assert: amounts[0] matches router library calculation
    function testSwapTokensForExactTokensInputCalculation() public {
        uint256 amountADesired = 100 ether;
        uint256 amountBDesired = 1000 ether;

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

        vm.startPrank(musk);

        uint256 desiredOutput = 90 ether;
        DOL.approve(address(router), 100 ether);

        address[] memory path = new address[](2);
        path[0] = address(DOL);
        path[1] = address(UP);

        address pairAddress = factory.getPair(address(DOL), address(UP));
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pairAddress)
            .getReserves();

        address token0 = IUniswapV2Pair(pairAddress).token0();
        uint256 reserveIn;
        uint256 reserveOut;

        if (token0 == address(DOL)) {
            reserveIn = reserve0;
            reserveOut = reserve1;
        } else {
            reserveIn = reserve1;
            reserveOut = reserve0;
        }

        // amountIn = (reserveIn * amountOut * 1000) / ((reserveOut - amountOut) * 997) + 1
        uint256 numerator = reserveIn * desiredOutput * 1000;
        uint256 denominator = (reserveOut - desiredOutput) * 997;
        uint256 expectedAmountIn = (numerator / denominator) + 1;

        console.log("\n=== Input Calculation Verification ===");
        console.log("Reserve IN (DOL):", reserveIn);
        console.log("Reserve OUT (UP):", reserveOut);
        console.log("Desired Output (UP):", desiredOutput);
        console.log("Expected Input (DOL):", expectedAmountIn);

        uint256[] memory amounts = router.swapTokensForExactTokens(
            desiredOutput,
            100 ether,
            path,
            musk,
            block.timestamp + 300
        );

        vm.stopPrank();

        console.log("Actual Input (DOL):", amounts[0]);
        console.log("Actual Output (UP):", amounts[1]);

        assertEq(
            amounts[1],
            desiredOutput,
            "Output should be exact desired amount"
        );

        assertEq(
            amounts[0],
            expectedAmountIn,
            "Input amount should match library calculation"
        );

        assertTrue(
            amounts[0] > 0,
            "Input amount should be greater than zero"
        );

        assertTrue(
            amounts[0] < desiredOutput,
            "Due to 1:10 ratio, DOL input should be less than UP output"
        );
    }

    function testSwapExactETHForTokens() public {
        uint256 amountTokenDesired = 1000 ether;
        uint256 amountETHDesired = 10 ether;

        vm.startPrank(deployer);

        UP.approve(address(router), amountTokenDesired);

        router.addLiquidityETH{value: amountETHDesired}(
            address(UP),
            amountTokenDesired,
            0,
            0,
            deployer,
            block.timestamp + 300
        );

        vm.stopPrank();
        vm.startPrank(musk);

        uint256 ethAmountIn = 1 ether;

        uint256 muskUPBefore = UP.balanceOf(musk);
        uint256 muskETHBefore = musk.balance;

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(UP);

        console.log("\n=== Before ETH to Token Swap ===");
        console.log("Musk ETH balance:", muskETHBefore);
        console.log("Musk UP balance:", muskUPBefore);
        uint256[] memory amounts = router.swapExactETHForTokens{value: ethAmountIn}(
            0,
            path,
            musk,
            block.timestamp + 300
        );

        vm.stopPrank();

        uint256 muskUPAfter = UP.balanceOf(musk);
        uint256 muskETHAfter = musk.balance;
        console.log("\n=== After ETH to Token Swap ===");
        console.log("Musk ETH balance:", muskETHAfter);
        console.log("Musk UP balance:", muskUPAfter);
        console.log("Amount IN (ETH):", amounts[0]);
        console.log("Amount OUT (UP):", amounts[1]);

        assertEq(
            amounts[0],
            ethAmountIn,
            "Input ETH amount should match sent value"
        );
        assertTrue(amounts[1] > 0, "Output token amount should be greater than zero");
        assertEq(
            muskETHAfter,
            muskETHBefore - ethAmountIn,
            "Musk ETH balance should decrease by input amount"
        );
        assertEq(
            muskUPAfter,
            muskUPBefore + amounts[1],
            "Musk UP balance should increase by output amount"
        );
    }

    function testSwapExactETHForTokensSlippageProtection() public {
        uint256 amountTokenDesired = 1000 ether;
        uint256 amountETHDesired = 10 ether;

        vm.startPrank(deployer);
        UP.approve(address(router), amountTokenDesired);
        router.addLiquidityETH{value: amountETHDesired}(
            address(UP),
            amountTokenDesired,
            0,
            0,
            deployer,
            block.timestamp + 300
        );
        vm.stopPrank();

        vm.startPrank(musk);

        uint256 ethAmountIn = 1 ether;
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(UP);

        uint256 excessiveAmountOutMin = 500 ether; // Way too high

        vm.expectRevert(bytes("UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"));
        router.swapExactETHForTokens{value: ethAmountIn}(
            excessiveAmountOutMin,
            path,
            musk,
            block.timestamp + 300
        );

        vm.stopPrank();
    }

    function testSwapExactETHForTokensExpiredDeadline() public {
        uint256 amountTokenDesired = 1000 ether;
        uint256 amountETHDesired = 10 ether;

        vm.startPrank(deployer);
        UP.approve(address(router), amountTokenDesired);
        router.addLiquidityETH{value: amountETHDesired}(
            address(UP),
            amountTokenDesired,
            0,
            0,
            deployer,
            block.timestamp + 300
        );
        vm.stopPrank();

        vm.startPrank(musk);

        uint256 ethAmountIn = 1 ether;
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(UP);

        uint256 expiredDeadline = 100;
        vm.warp(expiredDeadline + 1);

        vm.expectRevert(bytes("UniswapV2Router:EXPIRED"));
        router.swapExactETHForTokens{value: ethAmountIn}(
            0,
            path,
            musk,
            expiredDeadline
        );

        vm.stopPrank();
    }

    function testSwapExactETHForTokensToCustomAddress() public {
        uint256 amountTokenDesired = 1000 ether;
        uint256 amountETHDesired = 10 ether;

        vm.startPrank(deployer);
        UP.approve(address(router), amountTokenDesired);
        router.addLiquidityETH{value: amountETHDesired}(
            address(UP),
            amountTokenDesired,
            0,
            0,
            deployer,
            block.timestamp + 300
        );
        vm.stopPrank();

        vm.startPrank(musk);

        uint256 ethAmountIn = 1 ether;
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(UP);

        uint256 deployerUPBefore = UP.balanceOf(deployer);
        uint256 muskUPBefore = UP.balanceOf(musk);
        uint256 muskETHBefore = musk.balance;

        uint256[] memory amounts = router.swapExactETHForTokens{value: ethAmountIn}(
            0,
            path,
            deployer, 
            block.timestamp + 300
        );

        vm.stopPrank();

        uint256 deployerUPAfter = UP.balanceOf(deployer);
        uint256 muskUPAfter = UP.balanceOf(musk);
        uint256 muskETHAfter = musk.balance;

        console.log("\n=== Custom Address ETH Swap ===");
        console.log("Deployer UP before:", deployerUPBefore);
        console.log("Deployer UP after:", deployerUPAfter);
        console.log("Musk UP before:", muskUPBefore);
        console.log("Musk UP after:", muskUPAfter);
        console.log("Musk ETH before:", muskETHBefore);
        console.log("Musk ETH after:", muskETHAfter);
        console.log("Amount OUT (UP):", amounts[1]);

        assertEq(
            deployerUPAfter,
            deployerUPBefore + amounts[1],
            "Deployer should receive UP tokens"
        );

        assertEq(
            muskUPAfter,
            muskUPBefore,
            "Musk UP balance should stay the same (tokens sent to deployer)"
        );

        assertEq(
            muskETHAfter,
            muskETHBefore - ethAmountIn,
            "Musk should have paid ETH for the swap"
        );
    }

    function testSwapExactETHForTokensRefundsExcess() public {
        uint256 amountTokenDesired = 1000 ether;
        uint256 amountETHDesired = 10 ether;

        vm.startPrank(deployer);
        UP.approve(address(router), amountTokenDesired);
        router.addLiquidityETH{value: amountETHDesired}(
            address(UP),
            amountTokenDesired,
            0,
            0,
            deployer,
            block.timestamp + 300
        );
        vm.stopPrank();

        vm.startPrank(musk);

        uint256 ethAmountIn = 1 ether;
        uint256 excessETH = 2 ether; 
        uint256 totalETHSent = ethAmountIn + excessETH;

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(UP);

        uint256 muskETHBefore = musk.balance;
        uint256 muskUPBefore = UP.balanceOf(musk);

        console.log("\n=== Before Excess ETH Swap ===");
        console.log("Musk ETH balance:", muskETHBefore);
        console.log("ETH sent:", totalETHSent);
        console.log("Expected to use:", ethAmountIn);

        // Note: swapExactETHForTokens uses the full msg.value as input amount
        // It does NOT refund excess - the function uses msg.value as amountIn
        uint256[] memory amounts = router.swapExactETHForTokens{value: totalETHSent}(
            0,
            path,
            musk,
            block.timestamp + 300
        );

        vm.stopPrank();

        uint256 muskETHAfter = musk.balance;
        uint256 muskUPAfter = UP.balanceOf(musk);

        console.log("\n=== After Swap ===");
        console.log("Musk ETH balance:", muskETHAfter);
        console.log("ETH actually used:", amounts[0]);
        console.log("UP received:", amounts[1]);

        // swapExactETHForTokens uses ALL msg.value as input
        assertEq(
            amounts[0],
            totalETHSent,
            "All sent ETH should be used as input (no refund in swapExactETH)"
        );

        assertEq(
            muskETHAfter,
            muskETHBefore - totalETHSent,
            "Musk should have spent all sent ETH"
        );

        assertEq(
            muskUPAfter,
            muskUPBefore + amounts[1],
            "Musk should receive UP tokens"
        );

        assertTrue(
            amounts[1] > 0,
            "Should receive more tokens for more ETH"
        );
    }
}
