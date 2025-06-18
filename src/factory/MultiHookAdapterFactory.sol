// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {DeploymentLibrary} from "./DeploymentLibrary.sol";
import {AddressFinder} from "./AddressFinder.sol";

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
    function predictMultiHookAdapterAddress(
        IPoolManager poolManager,
        uint24 defaultFee,
        bytes32 salt
    ) external view returns (address adapter) {
        bytes memory bytecode = DeploymentLibrary.getMultiHookAdapterBytecode(poolManager, defaultFee);
        adapter = DeploymentLibrary.computeCreate2Address(bytecode, salt, address(this));
    }
    
    /// @notice Predict the address of a PermissionedMultiHookAdapter deployment
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
    function deployToHookAddress(
        IPoolManager poolManager,
        uint24 defaultFee,
        address targetHookAddress
    ) external returns (address adapter) {
        DeploymentLibrary.validateParameters(poolManager, defaultFee);
        
        bytes memory bytecode = DeploymentLibrary.getMultiHookAdapterBytecode(poolManager, defaultFee);
        
        (bytes32 salt, bool found) = AddressFinder.findSaltForTarget(
            bytecode, targetHookAddress, address(this), 1000
        );
        
        require(found, "Could not find salt for target address");
        
        adapter = DeploymentLibrary.deployWithCreate2(bytecode, salt);
        emit MultiHookAdapterDeployed(adapter, address(poolManager), defaultFee, msg.sender);
    }
    
    /// @notice Compute the CREATE2 address for given parameters
    function computeCreate2Address(bytes memory bytecode, bytes32 salt) public view returns (address addr) {
        addr = DeploymentLibrary.computeCreate2Address(bytecode, salt, address(this));
    }
}