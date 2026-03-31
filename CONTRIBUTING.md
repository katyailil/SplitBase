# Contributing to SplitBase

Thank you for your interest in contributing to SplitBase! This document provides guidelines and instructions for contributing to this on-chain revenue distribution protocol on Base.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Submitting Changes](#submitting-changes)
- [Security Considerations](#security-considerations)
- [Contribution Areas](#contribution-areas)

## Code of Conduct

This project adheres to a standard of professional conduct. Be respectful, constructive, and inclusive in all interactions.

## Getting Started

### Prerequisites

- **Git**: For version control
- **Foundry**: Ethereum development toolkit
- **Node.js** (optional): For additional tooling
- **Base Testnet ETH**: For testing (get from [Base Sepolia Faucet](https://www.coinbase.com/faucets/base-sepolia-faucet))

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/katyailil/SplitBase.git
   cd SplitBase
   ```

2. **Install Foundry**:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

3. **Install dependencies**:
   ```bash
   forge install
   ```

4. **Build the project**:
   ```bash
   forge build
   ```

## Development Environment

### Environment Setup

Create a `.env` file from the example:

```bash
cp .env.example .env
```

Configure the following variables:

```env
# RPC Endpoints
BASE_SEPOLIA_RPC=https://sepolia.base.org
BASE_MAINNET_RPC=https://mainnet.base.org

# Private Key (for testing only - never commit real keys)
PRIVATE_KEY=0x...

# Etherscan API for verification
ETHERSCAN_API_KEY=your_api_key
```

### Fork Testing

SplitBase is designed for Base network. Test with Base Sepolia fork:

```bash
forge test --fork-url $BASE_SEPOLIA_RPC
```

## Project Structure

```
SplitBase/
├── src/
│   ├── SplitBasePool.sol          # Core pool logic
│   ├── SplitBaseRegistry.sol      # Pool registry and discovery
│   ├── SplitBaseExecutor.sol      # Distribution execution
│   └── interfaces/                 # Contract interfaces
├── test/
│   ├── SplitBasePool.t.sol        # Pool tests
│   ├── SplitBaseRegistry.t.sol    # Registry tests
│   └── mocks/                      # Mock contracts
├── docs/
│   ├── ARCHITECTURE.md            # Technical architecture
│   └── DOMAIN_MODEL.md            # Business concepts
├── script/
│   └── Deploy.s.sol               # Deployment scripts
├── foundry.toml                   # Foundry configuration
└── README.md                      # Project documentation
```

### Core Components

1. **SplitBasePool**: Manages recipient shares and distributions
   - Percentage and unit-based share models
   - Bucket categorization (TEAM, INVESTORS, TREASURY, etc.)
   - Revenue source tracking

2. **SplitBaseRegistry**: Centralized pool management
   - Pool registration and discovery
   - Metadata storage
   - Access control

3. **SplitBaseExecutor**: Automated execution layer
   - Base Pay integration
   - Distribution triggering
   - Gas optimization

## Coding Standards

### Solidity Style Guide

- **Version**: Solidity ^0.8.20
- **License**: MIT (unless specified otherwise)
- **Style**: Follow [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html)

### Naming Conventions

```solidity
// Contracts: PascalCase
contract SplitBasePool { }

// Interfaces: PascalCase with I prefix
interface ISplitBasePool { }

// Libraries: PascalCase
library SplitBaseMath { }

// Functions: camelCase
function createPool(address[] calldata recipients, uint256[] calldata shares) external;

// Variables: camelCase
uint256 public totalShares;

// Constants: UPPER_SNAKE_CASE
uint256 public constant MAX_RECIPIENTS = 50;

// Events: PascalCase with description
event PoolCreated(uint256 indexed poolId, address creator);
```

### Code Formatting

Format code before committing:

```bash
forge fmt
```

## Testing Guidelines

### Running Tests

```bash
# Run all tests
forge test

# Run with gas report
forge test --gas-report

# Run specific test
forge test --match-test testCreatePool

# Run with verbosity
forge test -vvv

# Run with Base Sepolia fork
forge test --fork-url https://sepolia.base.org
```

### Test Structure

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SplitBasePool.sol";

contract SplitBasePoolTest is Test {
    SplitBasePool pool;
    
    function setUp() public {
        pool = new SplitBasePool();
    }
    
    function test_CreatePool() public {
        // Arrange
        address[] memory recipients = new address[](2);
        recipients[0] = address(1);
        recipients[1] = address(2);
        
        uint256[] memory shares = new uint256[](2);
        shares[0] = 50;
        shares[1] = 50;
        
        // Act
        uint256 poolId = pool.createPool(recipients, shares);
        
        // Assert
        assertEq(poolId, 1);
        assertEq(pool.getRecipientCount(poolId), 2);
    }
    
    function test_RevertWhen_InvalidShares() public {
        // Test revert conditions
    }
}
```

### Test Coverage Areas

- **Pool Creation**: Valid and invalid configurations
- **Share Calculations**: Precision and rounding
- **Distributions**: USDC transfers and accounting
- **Access Control**: Permission checks
- **Upgradeability**: Proxy pattern behavior
- **Edge Cases**: Empty pools, single recipient, maximum recipients

## Submitting Changes

### Branch Naming

- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates
- `test/description` - Test additions

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add support for recurring distributions
fix: correct share calculation precision
docs: update architecture diagram
test: add edge case coverage for empty pools
refactor: optimize gas usage in distribution loop
```

### Pull Request Process

1. **Create a branch**: `git checkout -b feature/your-feature`
2. **Make changes**: Write code, tests, and documentation
3. **Run tests**: Ensure all tests pass
4. **Format code**: Run `forge fmt`
5. **Commit**: Use conventional commit format
6. **Push**: `git push origin feature/your-feature`
7. **Create PR**: Open a pull request with clear description

### PR Description Template

```markdown
## Summary
Brief description of changes

## Changes
- Change 1
- Change 2

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Gas snapshots updated (if applicable)

## Security Considerations
Any security implications or considerations
```

## Security Considerations

SplitBase handles financial distributions. Security is critical:

### Critical Checks

- **Reentrancy**: Use checks-effects-interactions pattern
- **Integer Overflow**: Use SafeMath or Solidity 0.8+ built-in checks
- **Access Control**: Verify permissions on all sensitive functions
- **Precision Loss**: Test share calculations thoroughly
- **USDC Transfers**: Handle transfer failures and non-standard tokens

### Security Checklist

Before submitting changes that affect fund handling:

- [ ] Reentrancy guards in place where needed
- [ ] All external calls after state changes
- [ ] Input validation on all public functions
- [ ] Access control on admin functions
- [ ] Events emitted for all state changes
- [ ] No hardcoded addresses (use configuration)

### Reporting Vulnerabilities

For security issues, please email the maintainers directly rather than opening a public issue.

## Contribution Areas

### High Priority

1. **Gas Optimization**: Reduce distribution costs
2. **Additional Buckets**: New revenue categorization types
3. **Multi-Token Support**: Extend beyond USDC
4. **Subgraph Integration**: Indexing and analytics

### Medium Priority

1. **Frontend Examples**: React/Vue integration samples
2. **Documentation**: Tutorials and guides
3. **Test Coverage**: Increase branch coverage
4. **Deployment Scripts**: Mainnet deployment automation

### Good First Issues

1. **Documentation**: Fix typos, clarify explanations
2. **Tests**: Add edge case coverage
3. **Events**: Add missing event emissions
4. **Comments**: Improve code documentation

## Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Base Documentation](https://docs.base.org/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [Solidity Documentation](https://docs.soliditylang.org/)

## Questions?

- Open an issue for bugs or feature requests
- Join the community discussions
- Review existing PRs for context

Thank you for contributing to SplitBase! 🚀