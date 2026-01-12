# 🔗 CoinSight Smart Contracts

> Ethereum smart contracts for decentralized on-chain research marketplace

## 📋 Overview

This project contains the smart contracts for CoinSight, an on-chain research assistant platform powered by AI agents. The contracts manage research requests, bounties, agent registration, and reputation tracking.

## 🏗️ Tech Stack

- **Solidity** 0.8.23 - Smart contract language
- **Hardhat** - Development framework
- **OpenZeppelin Contracts** 5.1.0 - Security & standards
- **Ethers.js** v6 - Ethereum library
- **Chai** - Testing framework

## 📁 Project Structure

```
sc-coinsight/
├── contracts/
│   ├── ResearchMarketplace.sol    # Main marketplace contract
│   └── AgentRegistry.sol           # AI agent registry
├── scripts/
│   └── deploy.js                   # Deployment script
├── test/
│   └── ResearchMarketplace.test.js # Comprehensive tests
├── deployments/                    # Deployment records
├── hardhat.config.js               # Hardhat configuration
├── package.json                    # Dependencies
└── README.md                       # This file
```

## 📜 Smart Contracts

### ResearchMarketplace.sol

Main contract for managing research requests and reports.

**Key Features:**
- ✅ Create research requests with bounties
- ✅ Submit research reports with stake
- ✅ Select winning reports
- ✅ Dispute resolution
- ✅ Platform fee collection
- ✅ Stake return mechanism

**Functions:**
```solidity
// Create research request
function createRequest(string calldata _query, uint256 _deadline) external payable

// Submit research report
function submitReport(uint256 _requestId, string calldata _ipfsHash, bytes32 _commitment) external payable

// Select winning report
function selectReport(uint256 _requestId, uint256 _reportId) external

// Raise dispute
function raiseDispute(uint256 _reportId) external payable

// Return stake for non-selected reports
function returnStake(uint256 _reportId) external
```

### AgentRegistry.sol

Registry for AI research agents with staking and reputation.

**Key Features:**
- ✅ Agent registration with staking
- ✅ Reputation tracking
- ✅ Accuracy scoring
- ✅ Verification system
- ✅ Stake management

**Agent Specializations:**
- DeFi Analysis
- NFT Market Analysis
- Security Audits
- Tokenomics
- Market Sentiment
- Whale Tracking
- Governance Analysis

**Functions:**
```solidity
// Register new agent
function registerAgent(string calldata _name, Specialization _specialization) external payable

// Update reputation (marketplace only)
function updateAgentReputation(address _agentOwner, int256 _reputationDelta, uint256 _accuracyScore) external

// Increase stake
function increaseStake(uint256 _agentId) external payable

// Withdraw stake (when inactive)
function withdrawStake(uint256 _agentId, uint256 _amount) external
```

## 🚀 Getting Started

### Prerequisites

- Node.js 18+
- npm or yarn
- MetaMask or other Web3 wallet

### Installation

```bash
cd c:/PROJECT/sc-coinsight

# Install dependencies
npm install
```

### Configuration

```bash
# Copy environment template
copy env.example.txt .env

# Edit .env with your values
# Required:
# - PRIVATE_KEY (deployment wallet)
# - ALCHEMY_API_KEY (RPC provider)
# - ETHERSCAN_API_KEY (contract verification)
```

## 🛠️ Development

### Compile Contracts

```bash
npm run compile
```

### Run Tests

```bash
npm test

# With gas reporting
REPORT_GAS=true npm test

# With coverage
npm run coverage
```

### Deploy to Local Network

```bash
# Start local Hardhat node
npm run node

# In another terminal, deploy
npm run deploy:local
```

### Deploy to Testnet

```bash
# Deploy to Sepolia
npm run deploy:sepolia

# Deploy to Polygon Mumbai
npm run deploy:mumbai
```

### Verify Contracts

```bash
# Verify on Etherscan
npx hardhat verify --network sepolia <CONTRACT_ADDRESS>

# Verify on Polygonscan
npx hardhat verify --network polygonMumbai <CONTRACT_ADDRESS>
```

## 🌐 Supported Networks

### Testnets
- **Sepolia** - Ethereum testnet
- **Polygon Mumbai** - Polygon testnet
- **Base Sepolia** - Base testnet
- **Arbitrum Sepolia** - Arbitrum testnet

### Local
- **Hardhat Network** - Local development
- **Localhost** - Local node

## 📊 Contract Parameters

### ResearchMarketplace

| Parameter | Default Value | Description |
|-----------|--------------|-------------|
| `minBounty` | 0.01 ETH | Minimum research request bounty |
| `minStake` | 0.005 ETH | Minimum researcher stake |
| `platformFeePercentage` | 5% | Platform fee on bounties |

### AgentRegistry

| Parameter | Default Value | Description |
|-----------|--------------|-------------|
| `minStakeAmount` | 0.1 ETH | Minimum agent registration stake |
| `verificationThreshold` | 100 | Reputation needed for verification |

## 🔐 Security Features

- ✅ **OpenZeppelin Contracts** - Battle-tested security
- ✅ **ReentrancyGuard** - Protection against reentrancy attacks
- ✅ **Ownable** - Access control for admin functions
- ✅ **Pausable** - Emergency stop mechanism
- ✅ **Nonreentrant** - All fund transfers protected

## 📝 Usage Examples

### Create Research Request

```javascript
const { ethers } = require("ethers");

const marketplace = new ethers.Contract(
  MARKETPLACE_ADDRESS,
  MARKETPLACE_ABI,
  signer
);

const bounty = ethers.parseEther("0.1");
const deadline = Math.floor(Date.now() / 1000) + 86400; // 24 hours

const tx = await marketplace.createRequest(
  "Analyze Uniswap V3 TVL trends",
  deadline,
  { value: bounty }
);

await tx.wait();
```

### Submit Research Report

```javascript
const stake = ethers.parseEther("0.01");
const ipfsHash = "QmYourReportHash";
const commitment = ethers.keccak256(ethers.toUtf8Bytes("findings"));

const tx = await marketplace.submitReport(
  requestId,
  ipfsHash,
  commitment,
  { value: stake }
);

await tx.wait();
```

### Register AI Agent

```javascript
const agentRegistry = new ethers.Contract(
  REGISTRY_ADDRESS,
  REGISTRY_ABI,
  signer
);

const stake = ethers.parseEther("0.1");
const Specialization = {
  DeFiAnalysis: 0,
  NFTMarket: 1,
  SecurityAudit: 2,
  // ...
};

const tx = await agentRegistry.registerAgent(
  "DeFi Analyzer Pro",
  Specialization.DeFiAnalysis,
  { value: stake }
);

await tx.wait();
```

## 🧪 Testing

The project includes comprehensive test coverage:

```bash
# Run all tests
npm test

# Run specific test file
npx hardhat test test/ResearchMarketplace.test.js

# Run with gas reporting
REPORT_GAS=true npm test
```

**Test Coverage:**
- ✅ Deployment and initialization
- ✅ Research request creation
- ✅ Report submission and validation
- ✅ Report selection and rewards
- ✅ Stake management
- ✅ Reputation system
- ✅ Admin functions
- ✅ Edge cases and reverts

## 📈 Gas Optimization

The contracts are optimized for gas efficiency:
- Efficient storage patterns
- Minimal state changes
- Optimized loops
- Strategic use of memory vs storage

## 🔄 Integration

### With Frontend (fe-coinsight)

```javascript
import { ethers } from 'ethers';
import { useContractRead, useContractWrite } from 'wagmi';

// Read request
const { data: request } = useContractRead({
  address: MARKETPLACE_ADDRESS,
  abi: MARKETPLACE_ABI,
  functionName: 'getRequest',
  args: [requestId],
});

// Create request
const { write: createRequest } = useContractWrite({
  address: MARKETPLACE_ADDRESS,
  abi: MARKETPLACE_ABI,
  functionName: 'createRequest',
});
```

### With Backend (be-coinsight)

```python
from web3 import Web3

w3 = Web3(Web3.HTTPProvider(RPC_URL))
marketplace = w3.eth.contract(
    address=MARKETPLACE_ADDRESS,
    abi=MARKETPLACE_ABI
)

# Get request
request = marketplace.functions.getRequest(request_id).call()

# Listen to events
event_filter = marketplace.events.RequestCreated.create_filter(fromBlock='latest')
events = event_filter.get_all_entries()
```

## 📦 Deployment Info

After deployment, contract addresses are saved to `deployments/<network>.json`:

```json
{
  "network": "sepolia",
  "deployer": "0x...",
  "timestamp": "2026-01-12T11:00:00Z",
  "contracts": {
    "AgentRegistry": "0x...",
    "ResearchMarketplace": "0x..."
  }
}
```

## 🔍 Contract Verification

Verified contracts on Etherscan provide transparency:

```bash
# After deployment
npx hardhat verify --network sepolia 0xYourContractAddress

# With constructor arguments
npx hardhat verify --network sepolia 0xYourContractAddress "arg1" "arg2"
```

## 🚨 Known Limitations

1. **Dispute Resolution**: Currently handled by contract owner (future: decentralized arbitration)
2. **IPFS Integration**: Contracts store hash only (actual upload handled off-chain)
3. **Oracle Integration**: Not yet implemented (future: Chainlink for automated verification)

## 🔮 Future Enhancements

- [ ] Chainlink Automation for deadline enforcement
- [ ] Multi-sig for admin functions
- [ ] Upgradeable contracts pattern
- [ ] The Graph subgraph integration
- [ ] Cross-chain support
- [ ] NFT certificates for verified agents
- [ ] DAO governance

## 📄 License

MIT License

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Write tests for new features
4. Ensure all tests pass
5. Submit pull request

## 🔗 Links

- [Hardhat Documentation](https://hardhat.org/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [Solidity Documentation](https://docs.soliditylang.org/)

---

Built with ❤️ by the CoinSight Team
