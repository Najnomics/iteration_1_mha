// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {MultiHookAdapter} from "../MultiHookAdapter.sol";
import {PermissionedMultiHookAdapter} from "../PermissionedMultiHookAdapter.sol";

/// @title MultiHookAdapterFactory
/// @notice Optimized factory for deploying MultiHookAdapter instances  
contract MultiHookAdapterFactory {
    
    /// @dev Error for invalid parameters
    error InvalidParams();
    
    /// @notice Events for deployments
    event MultiHookAdapterDeployed(address indexed adapter, address indexed poolManager, uint24 defaultFee, address indexed deployer);
    event PermissionedAdapterDeployed(address indexed adapter, address indexed poolManager, uint24 defaultFee, address indexed governance, address hookManager, address deployer);
    
    /// @notice Deploy MultiHookAdapter
    function deployMultiHookAdapter(IPoolManager poolManager, uint24 defaultFee, bytes32 salt) external returns (address adapter) {
        if (address(poolManager) == address(0) || defaultFee > 1_000_000) revert InvalidParams();
        
        bytes memory bytecode = abi.encodePacked(type(MultiHookAdapter).creationCode, abi.encode(poolManager, defaultFee));
        
        assembly {
            adapter := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(adapter) { revert(0, 0) }
        }
        
        emit MultiHookAdapterDeployed(adapter, address(poolManager), defaultFee, msg.sender);
    }
    
    /// @notice Deploy PermissionedMultiHookAdapter
    function deployPermissionedMultiHookAdapter(
        IPoolManager poolManager,
        uint24 defaultFee,
        address governance,
        address hookManager,
        bool enableHookManagement,
        bytes32 salt
    ) external returns (address adapter) {
        if (address(poolManager) == address(0) || defaultFee > 1_000_000 || governance == address(0)) revert InvalidParams();
        if (enableHookManagement && hookManager == address(0)) revert InvalidParams();
        
        bytes memory bytecode = abi.encodePacked(
            type(PermissionedMultiHookAdapter).creationCode,
            abi.encode(poolManager, defaultFee, governance, hookManager, enableHookManagement)
        );
        
        assembly {
            adapter := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(adapter) { revert(0, 0) }
        }
        
        emit PermissionedAdapterDeployed(adapter, address(poolManager), defaultFee, governance, hookManager, msg.sender);
    }
    
    /// @notice Predict MultiHookAdapter address
    function predictMultiHookAdapterAddress(IPoolManager poolManager, uint24 defaultFee, bytes32 salt) external view returns (address) {
        bytes memory bytecode = abi.encodePacked(type(MultiHookAdapter).creationCode, abi.encode(poolManager, defaultFee));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));
        return address(uint160(uint256(hash)));
    }
    
    /// @notice Predict PermissionedMultiHookAdapter address
    function predictPermissionedMultiHookAdapterAddress(
        IPoolManager poolManager,
        uint24 defaultFee,
        address governance,
        address hookManager,
        bool enableHookManagement,
        bytes32 salt
    ) external view returns (address) {
        bytes memory bytecode = abi.encodePacked(
            type(PermissionedMultiHookAdapter).creationCode,
            abi.encode(poolManager, defaultFee, governance, hookManager, enableHookManagement)
        );
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));
        return address(uint160(uint256(hash)));
    }
    
    /// @notice Deploy to specific hook address
    function deployToHookAddress(IPoolManager poolManager, uint24 defaultFee, address targetAddress) external returns (address adapter) {
        if (address(poolManager) == address(0) || defaultFee > 1_000_000) revert InvalidParams();
        
        bytes memory bytecode = abi.encodePacked(type(MultiHookAdapter).creationCode, abi.encode(poolManager, defaultFee));
        
        for (uint256 i = 0; i < 1000; i++) {
            bytes32 salt = bytes32(i);
            bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));
            
            if (address(uint160(uint256(hash))) == targetAddress) {
                assembly {
                    adapter := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
                    if iszero(adapter) { revert(0, 0) }
                }
                emit MultiHookAdapterDeployed(adapter, address(poolManager), defaultFee, msg.sender);
                return adapter;
            }
        }
        
        revert("Could not find salt for target address");
    }
    
    /// @notice Compute CREATE2 address
    function computeCreate2Address(bytes memory bytecode, bytes32 salt) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));
        return address(uint160(uint256(hash)));
    }
}