# Uniswap V2 DEX - AMM Implementation

A complete implementation of Uniswap V2 automated market maker (AMM) protocol built with Solidity and Foundry. This project includes core contracts, routers, comprehensive documentation, and deployment scripts.

## 📚 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Documentation](#documentation)
- [Getting Started](#getting-started)
- [Deployment](#deployment)
- [Testing](#testing)
- [Project Structure](#project-structure)

## 🔍 Overview

This is a production-ready implementation of the Uniswap V2 protocol featuring:

- **Core AMM Logic**: Factory, Pair, and LP Token contracts with TWAP oracle support
- **Router Contracts**: Router01 (basic swaps & liquidity) and Router02 (with fee-on-transfer token support)
- **Multi-Network Deployment**: Scripts for Mainnet, Sepolia, and local Anvil
- **Comprehensive Documentation**: In-depth guides with 100+ interview questions

## ✨ Features

### Core Protocol

- ✅ Constant product AMM (`x * y = k`)
- ✅ Deterministic pair deployment via CREATE2
- ✅ Time-weighted average price (TWAP) oracles
- ✅ Flash swap support
- ✅ Protocol fee toggle (1/6 of LP fees)
- ✅ EIP-2612 permit for gasless approvals
- ✅ Reentrancy protection

### Router Features

- ✅ Add/remove liquidity for token pairs
- ✅ Add/remove liquidity with ETH
- ✅ Multi-hop token swaps
- ✅ Slippage protection
- ✅ Deadline enforcement
- ✅ Fee-on-transfer token support (Router02)
- ✅ Permit-based liquidity removal

## 🏗 Architecture

```
┌─────────────┐
│   Router    │ ◄── User entry point
└──────┬──────┘
       │
       ├──► Factory ──► Deploys pairs via CREATE2
       │
       └──► Pair (AMM vault)
              ├─► Inherits UniswapV2ERC20 (LP tokens)
              ├─► Uses Math library (sqrt, min)
              └─► Implements constant product invariant
```

### Contract Overview

| Contract             | Purpose                       | Key Features                           |
| -------------------- | ----------------------------- | -------------------------------------- |
| **UniswapV2Factory** | Pair registry & deployer      | CREATE2, fee governance                |
| **UniswapV2Pair**    | Core AMM vault                | Swaps, mint/burn LP, TWAP, flash swaps |
| **UniswapV2ERC20**   | LP token implementation       | EIP-2612 permit, infinite approval     |
| **Router01**         | Liquidity & swap orchestrator | Multi-hop swaps, slippage control      |
| **Router02**         | Enhanced router               | Fee-on-transfer token support          |
| **Math**             | Helper library                | Babylonian sqrt, min                   |

## 📖 Documentation

Comprehensive guides included in this repository:

- **[UniswapV2CoreContracts_Explained.md](./UniswapV2CoreContracts_Explained.md)** - Deep dive into Factory, Pair, LP tokens with 100+ interview questions
- **Router Documentation** - Detailed router architecture and execution flows

Each guide includes:

- Line-by-line code analysis
- Economic mechanics & mathematical proofs
- Security considerations & edge cases
- Interview question bank (junior to expert level)
- Real-world scenarios and debugging tips

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git
- Node.js (optional, for frontend integration)

### Installation

```bash
# Clone the repository
git clone https://github.com/UdayPandey01/dex-amm.git
cd dex-amm

# Install dependencies
forge install

# Build contracts
forge build
```

### Environment Setup

Create a `.env` file:

```bash
# Network RPC URLs
MAINNET_RPC_URL=
SEPOLIA_RPC_URL=
ANVIL_RPC_URL=http://127.0.0.1:8545

# Private Keys (NEVER commit these!)
MAINNET_PRIVATE_KEY=
SEPOLIA_PRIVATE_KEY=
ANVIL_PRIVATE_KEY=

# Etherscan API (for verification)
ETHERSCAN_API_KEY=
```

## 📦 Deployment

### Deploy Core Contracts (Factory + Pair)

```bash
# Deploy to local Anvil
forge script script/core/DeployUniswapV2.s.sol --rpc-url $ANVIL_RPC_URL --broadcast

# Deploy to Sepolia testnet
forge script script/core/DeployUniswapV2.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify

# Deploy to Ethereum Mainnet
forge script script/core/DeployUniswapV2.s.sol --rpc-url $MAINNET_RPC_URL --broadcast --verify
```

### Deploy Router

```bash
# Deploy Router02 to Anvil
forge script script/router/DeployUniswapV2Router.s.sol --rpc-url $ANVIL_RPC_URL --broadcast

# Deploy to Sepolia
forge script script/router/DeployUniswapV2Router.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

### Supported Networks

- **Ethereum Mainnet** (Chain ID: 1)
- **Sepolia Testnet** (Chain ID: 11155111)
- **Local Anvil** (Chain ID: 31337)

## 🧪 Testing

```bash
# Run all tests
forge test

# Run tests with gas reporting
forge test --gas-report

# Run specific test file
forge test --match-path test/router/integration/Router01Test.t.sol

# Run tests with verbosity
forge test -vvv

# Generate coverage report
forge coverage
```

## 📁 Project Structure

```
dex-amm/
├── src/
│   ├── core/
│   │   ├── UniswapV2Factory.sol
│   │   ├── UniswapV2Pair.sol
│   │   ├── UniswapV2ERC20.sol
│   │   ├── interfaces/
│   │   └── libraries/
│   └── router/
│       ├── Router01.sol
│       ├── Router02.sol
│       ├── WETH9.sol
│       ├── interfaces/
│       └── libraries/
├── script/
│   ├── core/
│   │   └── DeployUniswapV2.s.sol
│   └── router/
│       └── DeployUniswapV2Router.s.sol
├── test/
│   ├── mock/
│   │   └── TestERC20Mock.sol
│   ├── utils/
│   └── router/
│       └── integration/
├── UniswapV2CoreContracts_Explained.md
└── README.md
```

## 🛠 Foundry Toolkit

This project uses **Foundry** - a blazing fast, portable and modular toolkit for Ethereum development written in Rust.

### Common Commands

```bash
# Build contracts
forge build

# Run tests
forge test

# Format code
forge fmt

# Generate gas snapshots
forge snapshot

# Start local node
anvil

# Interact with contracts
cast <subcommand>

# Get help
forge --help
anvil --help
cast --help
```

## 🔐 Security Considerations

- ✅ Reentrancy guards on all state-changing functions
- ✅ Overflow/underflow protection via Solidity 0.8+
- ✅ Slippage and deadline protection
- ✅ Fee-on-transfer token handling in Router02
- ⚠️ Always audit contracts before mainnet deployment
- ⚠️ Use hardware wallets for deployer private keys

## 📝 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- [Uniswap V2 Core](https://github.com/Uniswap/v2-core)
- [Uniswap V2 Periphery](https://github.com/Uniswap/v2-periphery)
- [Foundry Book](https://book.getfoundry.sh/)


## 📧 Contact

- GitHub: [@UdayPandey01](https://github.com/UdayPandey01)
- Repository: [dex-amm](https://github.com/UdayPandey01/dex-amm)
