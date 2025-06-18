// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {DeploymentLibrary} from "./DeploymentLibrary.sol";

/// @title MultiHookAdapterFactory
/// @notice Optimized factory contract for deploying MultiHookAdapter instances
contract MultiHookAdapterFactory {
    
    /// @notice Event emitted when a new MultiHookAdapter is deployed
    event MultiHookAdapterDeployed(
        address indexed adapter,
        address indexed poolManager, 
        uint24 defaultFee,
        address indexed deployer
    );
    
    /// @notice Event emitted when a new PermissionedMultiHookAdapter is deployed
    event PermissionedMultiHookAdapterDeployed(
        address indexed adapter,
        address indexed poolManager,
        uint24 defaultFee,
        address indexed governance,
        address hookManager,
        address deployer
    );
    
    /// @notice Deploy a new immutable MultiHookAdapter
    /// @param poolManager The Uniswap V4 pool manager
    /// @param defaultFee The default fee in basis points (e.g., 3000 = 0.3%)
    /// @param salt Optional salt for deterministic deployment
    /// @return adapter The deployed adapter address
    function deployMultiHookAdapter(
        IPoolManager poolManager,
        uint24 defaultFee,
        bytes32 salt
    ) external returns (address adapter) {
        DeploymentLibrary.validateParameters(poolManager, defaultFee);
        
        bytes memory bytecode = DeploymentLibrary.getMultiHookAdapterBytecode(poolManager, defaultFee);
        adapter = DeploymentLibrary.deployWithCreate2(bytecode, salt);
        
        emit MultiHookAdapterDeployed(adapter, address(poolManager), defaultFee, msg.sender);
    }
    
    /// @notice Deploy a new permissioned MultiHookAdapter with governance
    /// @param poolManager The Uniswap V4 pool manager
    /// @param defaultFee The default fee in basis points
    /// @param governance The governance address for fee management
    /// @param hookManager The hook manager address for hook approvals
    /// @param enableHookManagement Whether to enable hook management features
    /// @param salt Optional salt for deterministic deployment
    /// @return adapter The deployed adapter address
    function deployPermissionedMultiHookAdapter(
        IPoolManager poolManager,
        uint24 defaultFee,
        address governance,
        address hookManager,
        bool enableHookManagement,
        bytes32 salt
    ) external returns (address adapter) {
        DeploymentLibrary.validatePermissionedParameters(
            poolManager, defaultFee, governance, hookManager, enableHookManagement
        );
        
        bytes memory bytecode = DeploymentLibrary.getPermissionedMultiHookAdapterBytecode(
            poolManager, defaultFee, governance, hookManager, enableHookManagement
        );
        adapter = DeploymentLibrary.deployWithCreate2(bytecode, salt);
        
        emit PermissionedMultiHookAdapterDeployed(
            adapter, address(poolManager), defaultFee, governance, hookManager, msg.sender
        );
    }
    
    /// @notice Predict the address of a MultiHookAdapter deployment
    /// @param poolManager The Uniswap V4 pool manager
    /// @param defaultFee The default fee in basis points
    /// @param salt The salt used for deployment
    /// @return adapter The predicted adapter address
    function predictMultiHookAdapterAddress(
        IPoolManager poolManager,
        uint24 defaultFee,
        bytes32 salt
    ) external view returns (address adapter) {
        bytes memory bytecode = DeploymentLibrary.getMultiHookAdapterBytecode(poolManager, defaultFee);
        adapter = DeploymentLibrary.computeCreate2Address(bytecode, salt, address(this));
    }
    
    /// @notice Predict the address of a PermissionedMultiHookAdapter deployment
    /// @param poolManager The Uniswap V4 pool manager
    /// @param defaultFee The default fee in basis points
    /// @param governance The governance address
    /// @param hookManager The hook manager address
    /// @param enableHookManagement Whether hook management is enabled
    /// @param salt The salt used for deployment
    /// @return adapter The predicted adapter address
    function predictPermissionedMultiHookAdapterAddress(
        IPoolManager poolManager,
        uint24 defaultFee,
        address governance,
        address hookManager,
        bool enableHookManagement,
        bytes32 salt
    ) external view returns (address adapter) {
        bytes memory bytecode = DeploymentLibrary.getPermissionedMultiHookAdapterBytecode(
            poolManager, defaultFee, governance, hookManager, enableHookManagement
        );
        adapter = DeploymentLibrary.computeCreate2Address(bytecode, salt, address(this));
    }
    
    /// @notice Deploy MultiHookAdapter to a specific hook-compatible address
    /// @param poolManager The Uniswap V4 pool manager
    /// @param defaultFee The default fee in basis points
    /// @param targetHookAddress The target address that should have valid hook permissions
    /// @return adapter The deployed adapter address
    function deployToHookAddress(
        IPoolManager poolManager,
        uint24 defaultFee,
        address targetHookAddress
    ) external returns (address adapter) {
        DeploymentLibrary.validateParameters(poolManager, defaultFee);
        
        bytes memory bytecode = DeploymentLibrary.getMultiHookAdapterBytecode(poolManager, defaultFee);
        
        // Try different salts until we find one that gives us the target address
        for (uint256 i = 0; i < 1000; i++) {
            bytes32 salt = bytes32(i);
            address predictedAddress = DeploymentLibrary.computeCreate2Address(
                bytecode, salt, address(this)
            );
            
            if (predictedAddress == targetHookAddress) {
                adapter = DeploymentLibrary.deployWithCreate2(bytecode, salt);
                emit MultiHookAdapterDeployed(adapter, address(poolManager), defaultFee, msg.sender);
                return adapter;
            }
        }
        
        revert("Could not find salt for target address");
    }
    
    /// @notice Compute the CREATE2 address for given parameters
    /// @param bytecode The contract bytecode
    /// @param salt The salt for CREATE2
    /// @return addr The computed address
    function computeCreate2Address(bytes memory bytecode, bytes32 salt) public view returns (address addr) {
        addr = DeploymentLibrary.computeCreate2Address(bytecode, salt, address(this));
    }
}