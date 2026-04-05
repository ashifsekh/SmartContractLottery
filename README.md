# 🎰 SmartContractLottery

A **provably fair, decentralized raffle system** built on Ethereum using Solidity. This project leverages **Chainlink VRF v2.5** for verifiable on-chain randomness and **Chainlink Automation** for trustless, time-based winner selection — with no centralized operator required.

> Built with [Foundry](https://book.getfoundry.sh/) · Solidity `^0.8.19` · Chainlink VRF v2.5 · Chainlink Automation

---

## Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Project Structure](#project-structure)
- [Contract Architecture](#contract-architecture)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Environment Setup](#environment-setup)
- [Usage](#usage)
  - [Local Development](#local-development)
  - [Deploy to Sepolia Testnet](#deploy-to-sepolia-testnet)
- [Testing](#testing)
- [Network Configurations](#network-configurations)
- [Security Considerations](#security-considerations)
- [Dependencies](#dependencies)

---

## Overview

Traditional lotteries rely on centralized authorities to pick winners — introducing trust assumptions and manipulation risks. **SmartContractLottery** eliminates this entirely:

- Players enter by sending ETH to the contract.
- After a configurable time interval, Chainlink Automation triggers the winner selection automatically.
- Chainlink VRF provides a cryptographically verifiable random number.
- The winner receives the entire ETH prize pool, trustlessly.

Nobody — not even the contract deployer — can influence or predict the outcome.

---

## How It Works

```
Players send ETH → Join player pool
         ↓
Chainlink Automation polls checkUpkeep()
         ↓
Conditions met? (time elapsed + has players + has balance + is open)
         ↓
performUpkeep() is triggered → requests randomness from Chainlink VRF
         ↓
fulfillRandomWords() receives verifiable random number
         ↓
Winner selected via random index → Full ETH balance transferred
         ↓
Raffle resets → New round begins automatically
```

**Upkeep conditions (all must be true):**
1. The configured time interval has elapsed since the last draw.
2. The raffle is in the `OPEN` state.
3. The contract holds a non-zero ETH balance.
4. At least one player has entered.
5. The Chainlink VRF subscription is funded with LINK.

---

## Project Structure

```
SmartContractLottery/
├── src/
│   └── Raffle.sol              # Core raffle contract
├── script/
│   ├── DeployRaffle.s.sol      # Deployment script (multi-chain aware)
│   ├── HelperConfig.s.sol      # Network config & mock setup
│   └── Interactions.sol        # VRF subscription helpers
├── test/
│   ├── unit/
│   │   └── RaffleTest.t.sol    # Comprehensive unit test suite
│   ├── integration/            # Integration tests (WIP)
│   └── mocks/
│       └── LinkToken.sol       # ERC-677 LINK token mock
├── lib/                        # Git submodule dependencies
├── foundry.toml                # Foundry configuration
└── remappings.txt              # Solidity import remappings
```

---

## Contract Architecture

### `Raffle.sol`

The core contract inherits from:
- `VRFConsumerBaseV2Plus` — Chainlink VRF v2.5 consumer base
- `AutomationCompatibleInterface` — Chainlink Automation compatibility

| Function | Visibility | Description |
|---|---|---|
| `enterRaffle()` | `external payable` | Enter the raffle by sending ≥ entrance fee |
| `checkUpkeep()` | `public view` | Returns whether automation upkeep is needed |
| `performUpkeep()` | `external` | Triggers randomness request and closes the raffle |
| `fulfillRandomWords()` | `internal override` | Receives VRF randomness, picks winner, pays out, resets |
| `getEntranceFee()` | `external view` | Returns the current entrance fee |
| `getRaffleState()` | `external view` | Returns `OPEN` (0) or `CALCULATING` (1) |
| `getPlayer(index)` | `external view` | Returns player address by index |
| `getRecentWinner()` | `external view` | Returns the most recent winner's address |
| `getNumberOfPlayers()` | `external view` | Returns current number of registered players |
| `getTimeStamp()` | `external view` | Returns timestamp of last raffle draw |

**Custom Errors:**

| Error | Condition |
|---|---|
| `Raffle__NotEnoughEthSent` | `msg.value` is below `i_entranceFee` |
| `Raffle__RaffleNotOpen` | Raffle is in `CALCULATING` state |
| `Raffle__TransferFailed` | ETH transfer to winner failed |
| `Raffle__UpkeepNotNeeded` | `performUpkeep` called without conditions being met |

---

## Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/) (`forge`, `cast`, `anvil`)
- [Git](https://git-scm.com/)
- A funded Ethereum wallet (for testnet deployments)
- A [Chainlink VRF subscription](https://vrf.chain.link/) (for testnet deployments)

### Installation

```bash
# Clone the repository
git clone https://github.com/ashifsekh/SmartContractLottery.git
cd SmartContractLottery

# Install dependencies (git submodules)
forge install
```

### Environment Setup

For testnet deployments, create a `.env` file:

```env
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/<YOUR_API_KEY>
PRIVATE_KEY=<YOUR_WALLET_PRIVATE_KEY>
ETHERSCAN_API_KEY=<YOUR_ETHERSCAN_API_KEY>
```

> ⚠️ **Never commit your `.env` file.** It is already listed in `.gitignore`.

---

## Usage

### Local Development

Start a local Anvil node and deploy:

```bash
# Start local blockchain
anvil

# In a separate terminal, deploy to local network
forge script script/DeployRaffle.s.sol --rpc-url http://localhost:8545 --broadcast
```

The `DeployRaffle` script automatically detects the local chain ID (`31337`) and deploys a `VRFCoordinatorV2_5Mock`, creates a subscription, and funds it — no manual setup required.

### Deploy to Sepolia Testnet

> **Before deploying**, ensure you have an active and funded Chainlink VRF v2.5 subscription on Sepolia. Update the `subscriptionId` in `HelperConfig.s.sol` accordingly.

```bash
forge script script/DeployRaffle.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

After deployment, register the contract as an **Upkeep** on [automation.chain.link](https://automation.chain.link) and add it as a **consumer** to your VRF subscription.

### Interacting with the Contract

```bash
# Check entrance fee
cast call <CONTRACT_ADDRESS> "getEntranceFee()" --rpc-url $SEPOLIA_RPC_URL

# Enter the raffle (send 0.01 ETH)
cast send <CONTRACT_ADDRESS> "enterRaffle()" \
  --value 0.01ether \
  --private-key $PRIVATE_KEY \
  --rpc-url $SEPOLIA_RPC_URL

# Check raffle state (0 = OPEN, 1 = CALCULATING)
cast call <CONTRACT_ADDRESS> "getRaffleState()" --rpc-url $SEPOLIA_RPC_URL

# Get most recent winner
cast call <CONTRACT_ADDRESS> "getRecentWinner()" --rpc-url $SEPOLIA_RPC_URL
```

---

## Testing

The project includes a comprehensive unit test suite covering all critical contract behaviors.

```bash
# Run all tests
forge test

# Run tests with verbose output
forge test -v

# Run with full traces
forge test -vvvv

# Run a specific test
forge test --match-test testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney -vvvv

# Generate a gas snapshot
forge snapshot

# Check code coverage
forge coverage
```

**Test coverage includes:**

| Category | Tests |
|---|---|
| Initialization | Raffle starts in `OPEN` state |
| Entry validation | Reverts on insufficient ETH, blocks entry during `CALCULATING` |
| Event emission | `EnteredRaffle` event emitted correctly |
| `checkUpkeep` | Returns false if no balance, not open, or interval not passed |
| `performUpkeep` | Reverts if upkeep not needed; transitions state and emits `requestId` |
| `fulfillRandomWords` | Picks winner, resets state, transfers full prize pool |
| Fuzz testing | 256 fuzz runs on randomized inputs (configured in `foundry.toml`) |

---

## Network Configurations

| Parameter | Sepolia Testnet | Local (Anvil) |
|---|---|---|
| Entrance Fee | 0.01 ETH | 0.01 ETH |
| Interval | 30 seconds | 30 seconds |
| VRF Coordinator | `0x9DdfaCa8...168B1B` | Mock (auto-deployed) |
| Callback Gas Limit | 500,000 | 500,000 |
| Request Confirmations | 3 | 3 |
| LINK Token | `0x779877...4624789` | Mock (auto-deployed) |

---

## Security Considerations

- **No owner privileges**: The contract has no `onlyOwner` functions. Once deployed, it operates autonomously.
- **Reentrancy**: Prize transfers use `.call{value: ...}("")` with proper state reset before transfer. The raffle state is set to `OPEN` and the players array is cleared before sending ETH, following the Checks-Effects-Interactions pattern.
- **Randomness**: Winner selection relies entirely on Chainlink VRF — the output cannot be predicted or manipulated by miners, the deployer, or any other party.
- **Automation**: No EOA is required to trigger winner selection. Chainlink Automation handles the upkeep call permissionlessly.
- **Custom errors**: Used throughout for gas-efficient reverts with descriptive on-chain context.

---

## Dependencies

| Library | Version | Purpose |
|---|---|---|
| [forge-std](https://github.com/foundry-rs/forge-std) | Latest | Testing utilities & scripting |
| [chainlink](https://github.com/smartcontractkit/chainlink) | Latest | VRF v2.5 & Automation interfaces |
| [chainlink-brownie-contracts](https://github.com/smartcontractkit/chainlink-brownie-contracts) | Latest | Additional Chainlink contract references |
| [solmate](https://github.com/transmissions11/solmate) | Latest | Gas-optimized ERC token standards (mocks) |

---

## License

This project is licensed under the **MIT License**. See the `SPDX-License-Identifier` headers in each source file.

---

<p align="center">
  Built by <a href="https://github.com/ashifsekh">Ashif Sekh</a> · Powered by Foundry & Chainlink
</p>
