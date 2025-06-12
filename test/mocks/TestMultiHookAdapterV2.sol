// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MultiHookAdapterBaseV2} from "../../src/base/MultiHookAdapterBaseV2.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {BeforeSwapDelta} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {IFeeCalculationStrategy} from "../../src/interfaces/IFeeCalculationStrategy.sol";

/// @title TestMultiHookAdapterV2//
/// @notice Test implementation of MultiHookAdapterBaseV2 for testing
contract TestMultiHookAdapterV2 is MultiHookAdapterBaseV2 {
    using PoolIdLibrary for PoolKey;

    constructor(
        IPoolManager _poolManager,
        uint24 _defaultFee,
        address _governance,
        bool _governanceEnabled
    ) MultiHookAdapterBaseV2(_poolManager, _defaultFee, _governance, _governanceEnabled) {}

    /// @notice Expose the internal mapping for testing purposes
    /// @param poolId The pool ID to get hooks for
    /// @return List of hooks registered for the pool
    function getHooksByPool(PoolId poolId) external view returns (IHooks[] memory) {
        return _hooksByPool[poolId];
    }

    /// @notice Expose the beforeSwapHookReturns mapping for testing
    /// @param poolId The pool ID to get return values for
    /// @return Array of BeforeSwapDelta values stored for the pool
    function getBeforeSwapHookReturns(PoolId poolId) external view returns (BeforeSwapDelta[] memory) {
        return beforeSwapHookReturns[poolId];
    }

    /// @notice Set beforeSwapHookReturns for testing
    function setBeforeSwapHookReturns(PoolId poolId, BeforeSwapDelta[] memory deltas) external {
        // Clear any existing entries
        delete beforeSwapHookReturns[poolId];

        // Add entries to the mapping
        for (uint256 i = 0; i < deltas.length; i++) {
            beforeSwapHookReturns[poolId].push(deltas[i]);
        }
    }
    
    /// @notice Expose fee configuration for testing
    function getPoolFeeConfig(PoolId poolId) external view returns (IFeeCalculationStrategy.FeeConfiguration memory) {
        return _poolFeeConfigs[poolId];
    }
    
    /// @notice Set fee configuration for testing
    function setPoolFeeConfig(PoolId poolId, IFeeCalculationStrategy.FeeConfiguration memory config) external {
        _poolFeeConfigs[poolId] = config;
    }

    /// @notice Must implement this method to make the contract concrete
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true,
            afterInitialize: true,
            beforeAddLiquidity: true,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: true,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: true,
            afterDonate: true,
            beforeSwapReturnDelta: true,
            afterSwapReturnDelta: true,
            afterAddLiquidityReturnDelta: true,
            afterRemoveLiquidityReturnDelta: true
        });
    }
}
