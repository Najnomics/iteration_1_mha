# MultiHookAdapter for Uniswap V4

A flexible adapter pattern enabling multiple hooks to operate simultaneously on a single Uniswap V4 pool, unlocking advanced composability and programmability.

## Challenge

Uniswap V4's architecture restricts each liquidity pool to a single hook contract, limiting the composability of pool behaviors. This constraint forces developers to build complex, monolithic hook contracts when multiple functionalities are needed for a single pool, or to deploy separate pools for different features, fragmenting liquidity.
---------
----
Common use cases requiring composition:
- Dynamic fee strategies with additional features like TWAMM operations
- On-chain bribes with custom liquidity incentives
- MEV protection combined with custom oracle implementations
- Cross-chain liquidity pools with bridge integration and slippage protection
- Yield-generating pools with automated compounders and fee optimizers
- Stablecoin pools with price oracle integration and emergency circuit breakers

## Solution

The MultiHookAdapter acts as an intelligent routing and aggregation layer between the Uniswap V4 PoolManager and multiple hook implementations. It elegantly removes the single-hook limitation without requiring any modifications to the core Uniswap V4 contracts.

### Key Features

- **Hook Execution Orchestration**: Manages ordered execution of multiple hooks for each lifecycle callback
- **Delta Aggregation**: Combines return values from hooks that modify balances
- **Fee Override Resolution**: Handles potential conflicts when multiple hooks try to override swap fees (currently, last hook wins)
- **Reentrancy Protection**: Ensures secure execution of hook callbacks

## Unlocking Composability in Uniswap V4

The MultiHookAdapter directly addresses a fundamental limitation in Uniswap V4's architecture: the restriction of each pool to a single hook contract. This constraint forces protocols to either deploy separate pools (fragmenting liquidity) or attempt to combine multiple hook functionalities into a single, monolithic hook contract (stifling composability and introducing significant programming overhead and security risks).

### Composability and Unified Liquidity

Without MultiHookAdapter, protocols face a difficult choice: deploy separate pools (fragmenting liquidity) or attempt to combine multiple hook functionalities into a single, monolithic hook contract. The latter approach stifles composability, as each protocol would need to re-implement and re-audit the combined functionality. It also adds significant programming overhead, especially for non-programmers or teams without deep Solidity expertise. Novice programmers might inadvertently introduce attack vectors or subtle bugs when trying to combine complex hook functionalities, as they may not fully understand the interactions between different hooks or the security implications of their combined logic.

MultiHookAdapter elegantly solves this dilemma by enabling protocols to compose multiple, audited hooks into a single pool. This not only keeps liquidity unified (improving price discovery and reducing slippage) but also allows protocols to leverage existing, battle-tested hook implementations without the need to re-implement or re-audit combined functionality. In essence, MultiHookAdapter unlocks the full potential of composability in Uniswap V4, enabling protocols to build sophisticated pool behaviors by combining multiple, specialized hooks, while maintaining the benefits of unified liquidity.

Crucially, MultiHookAdapter achieves this composability and extensibility without relying on upgradeable smart contracts, which can introduce very unexpected behavior on new upgrades. By composing multiple, immutable hooks into a single pool, protocols can evolve their pool functionality in a predictable and secure manner, without the risks associated with upgrading a monolithic, upgradeable hook contract.

### Benefits of Composable Hooks

- **Leverage Existing Implementations**: Protocols can use audited, battle-tested hooks without re-implementing or re-auditing combined functionality
- **Reduced Programming Overhead**: No need to combine complex hook functionalities into a single, monolithic contract
- **Enhanced Security**: Avoid potential attack vectors or bugs introduced by novice programmers when combining hooks
- **Unified Liquidity**: Keep liquidity in a single pool, improving price discovery and reducing slippage
- **Simplified Integration**: Protocols only need to integrate with one pool rather than multiple variants

### Enhanced User Experience

The ability to combine multiple features in a single pool represents a significant UX improvement:
- LPs interact with a single pool rather than managing positions across multiple pools
- Traders benefit from deeper liquidity and better execution
- Reduced cognitive load as users interact with a single pool
- Simplified portfolio tracking and tax reporting

### PermissionedMultiHookAdapter: Evolving Pool Functionality

While the base MultiHookAdapter enables multiple hooks to operate in a single pool, the PermissionedMultiHookAdapter adds the ability to evolve pool functionality over time without fragmenting liquidity. This is achieved through a permissioned registry of approved hooks that pools can add or remove as needed.

#### Eliminating Migration Overhead

Without PermissionedMultiHookAdapter, adding new functionality to an existing pool requires:
1. Deploying a new pool with the desired hook
2. LPs withdrawing liquidity from the old pool (incurring gas costs)
3. LPs re-depositing into the new pool (risking slippage)
4. Coordinating migration schedules to maintain depth

This process is gas-intensive, can create taxable events in some jurisdictions, and inevitably leads to liquidity being split across pools during transition periods.

With PermissionedMultiHookAdapter, pools can add or remove approved hooks without requiring LPs to migrate their positions. This flexibility is especially valuable for:

- **Protocol-Owned Liquidity**: DAOs can adapt pool strategies as market conditions evolve
- **Beta Features**: New hooks can be tested in production with a subset of pools before wider adoption
- **Security Updates**: Vulnerable hooks can be removed and replaced with audited alternatives
- **Feature Deprecation**: Unused or obsolete hooks can be removed to optimize gas usage

The permissioned registry ensures that only audited and approved hooks can be added to pools, maintaining security while enabling flexibility.

## Architecture

```
┌───────────────────┐
│   Uniswap V4      │
│   PoolManager     │
└─────────┬─────────┘
          │
          │ (Single hook interface)
          ▼
┌───────────────────┐
│  MultiHookAdapter │
└─────────┬─────────┘
          │
          │ (Hook execution orchestration)
          ▼
┌─────────┴─────────┐
│    Sub-hooks      │
└───────────────────┘
 Hook1 Hook2 Hook3...
```

### Core Components

- **MultiHookAdapterBase**: Abstract base contract implementing hook aggregation logic
- **MultiHookAdapter**: Concrete implementation with immutable hook sets
- **PermissionedMultiHookAdapter**: Implementation with managed hook modification rights

## Implementations

### MultiHookAdapter (Immutable)

Ideal for scenarios where deterministic pool behavior is essential, allowing liquidity providers to trust a fixed set of hooks that cannot be changed after pool deployment.

**Use Cases:**
- Fixed strategy pools with predefined behaviors
- Core infrastructure pools requiring stability guarantees
- Audited hook combinations with validated security properties

### PermissionedMultiHookAdapter

Features a permissioned registry of approved hooks maintained by governance or designated auditors. Pools using this adapter can only add or remove hooks that have been pre-approved and added to this registry.

**Key Points:**
- Hooks must first be audited and approved by the permissioned body
- Only approved hooks can be added to pools
- Provides flexibility while maintaining security guarantees
- Enables governance to adapt pool behaviors over time with vetted components

**Use Cases:**
- DAO-governed pools adapting to market conditions
- Protocol-owned liquidity with evolving strategies
- Beta features requiring potential updates

## Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/multihook-adapter.git
cd multihook-adapter

# Install dependencies
forge install

# Build
forge build

# Test
forge test
```

### Requirements

- Foundry (forge, anvil)
- Solidity ^0.8.24
- Node.js and npm (for deployment scripts)

## Tests

The project includes comprehensive tests for all hook callbacks and integration scenarios:

```bash
# Run all tests
forge test

# Run specific test suite
forge test --match-contract BeforeSwapTest

# Run with gas reporting
forge test --gas-report
```

### Test Coverage

- Hook registration and permissions
- BeforeInitialize/AfterInitialize callbacks
- BeforeSwap/AfterSwap with delta aggregation
- BeforeAddLiquidity/AfterAddLiquidity with delta returns
- BeforeRemoveLiquidity/AfterRemoveLiquidity with delta returns
- BeforeDonate/AfterDonate callbacks
- Fee override resolution
- Reversion conditions and error handling
- Security and reentrancy protection

## Security Considerations

- **Hook Ordering**: The execution order of hooks matters and should be carefully planned
- **Gas Consumption**: Multiple hooks increase gas usage proportionally
- **Delta Aggregation**: Combined hook returns might produce unexpected token flows
- **Fee Conflicts**: Last hook with fee override takes precedence

## Development Roadmap

- [x] MultiHookAdapterBase implementation
- [x] Test suite development
- [ ] MultiHookAdapter (immutable) implementation
- [ ] PermissionedMultiHookAdapter implementation
- [ ] Factory contracts for easy deployment
- [ ] Integration examples with popular hook patterns

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
