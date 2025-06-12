// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {MultiHookAdapter} from "../MultiHookAdapter.sol";
import {PermissionedMultiHookAdapter} from "../PermissionedMultiHookAdapter.sol";
import {IFeeCalculationStrategy} from "../interfaces/IFeeCalculationStrategy.sol";

/// @title MultiHookAdapterFactory//
/// @notice Factory contract for deploying MultiHookAdapter instances with proper hook addresses
contract MultiHookAdapterFactory {
    
    /// @notice Event emitted when a new MultiHookAdapter is deployed
    /// @param adapter The address of the deployed adapter
    /// @param poolManager The pool manager address
    /// @param defaultFee The default fee for the adapter
    /// @param deployer The address that deployed the adapter
    event MultiHookAdapterDeployed(
        address indexed adapter,
        address indexed poolManager, 
        uint24 defaultFee,
        address indexed deployer
    );
    
    /// @notice Event emitted when a new PermissionedMultiHookAdapter is deployed
    /// @param adapter The address of the deployed adapter
    /// @param poolManager The pool manager address
    /// @param defaultFee The default fee for the adapter
    /// @param governance The governance address
    /// @param hookManager The hook manager address
    /// @param deployer The address that deployed the adapter
    event PermissionedMultiHookAdapterDeployed(
        address indexed adapter,
        address indexed poolManager,
        uint24 defaultFee,
        address indexed governance,
        address hookManager,
        address deployer
    );
    
    /// @notice Error thrown when deployment parameters are invalid
    error InvalidDeploymentParameters();
    
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
        if (address(poolManager) == address(0)) revert InvalidDeploymentParameters();
        if (defaultFee > 1_000_000) revert InvalidDeploymentParameters(); // Max 100%
        
        // Deploy with CREATE2 for deterministic addresses
        bytes memory bytecode = abi.encodePacked(
            type(MultiHookAdapter).creationCode,
            abi.encode(poolManager, defaultFee)
        );
        
        assembly {
            adapter := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(adapter) { revert(0, 0) }
        }
        
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
        if (address(poolManager) == address(0)) revert InvalidDeploymentParameters();
        if (defaultFee > 1_000_000) revert InvalidDeploymentParameters();
        if (governance == address(0)) revert InvalidDeploymentParameters();
        if (enableHookManagement && hookManager == address(0)) revert InvalidDeploymentParameters();
        
        // Deploy with CREATE2 for deterministic addresses
        bytes memory bytecode = abi.encodePacked(
            type(PermissionedMultiHookAdapter).creationCode,
            abi.encode(poolManager, defaultFee, governance, hookManager, enableHookManagement)
        );
        
        assembly {
            adapter := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(adapter) { revert(0, 0) }
        }
        
        emit PermissionedMultiHookAdapterDeployed(
            adapter, 
            address(poolManager), 
            defaultFee, 
            governance, 
            hookManager, 
            msg.sender
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
        bytes memory bytecode = abi.encodePacked(
            type(MultiHookAdapter).creationCode,
            abi.encode(poolManager, defaultFee)
        );
        
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        
        adapter = address(uint160(uint256(hash)));
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
        bytes memory bytecode = abi.encodePacked(
            type(PermissionedMultiHookAdapter).creationCode,
            abi.encode(poolManager, defaultFee, governance, hookManager, enableHookManagement)
        );
        
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        
        adapter = address(uint160(uint256(hash)));
    }
    
    /// @notice Deploy MultiHookAdapter to a specific hook-compatible address
    /// @param poolManager The Uniswap V4 pool manager
    /// @param defaultFee The default fee in basis points
    /// @param targetHookAddress The target address that should have valid hook permissions
    /// @return adapter The deployed adapter address
    /// @dev This function will try different salts to find one that produces the target address
    function deployToHookAddress(
        IPoolManager poolManager,
        uint24 defaultFee,
        address targetHookAddress
    ) external returns (address adapter) {
        if (address(poolManager) == address(0)) revert InvalidDeploymentParameters();
        if (defaultFee > 1_000_000) revert InvalidDeploymentParameters();
        
        bytes memory bytecode = abi.encodePacked(
            type(MultiHookAdapter).creationCode,
            abi.encode(poolManager, defaultFee)
        );
        
        // Try different salts until we find one that gives us the target address
        for (uint256 i = 0; i < 1000; i++) {
            bytes32 salt = bytes32(i);
            
            bytes32 hash = keccak256(
                abi.encodePacked(
                    bytes1(0xff),
                    address(this),
                    salt,
                    keccak256(bytecode)
                )
            );
            
            address predictedAddress = address(uint160(uint256(hash)));
            
            if (predictedAddress == targetHookAddress) {
                // Found the right salt, deploy
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
    
    /// @notice Compute the CREATE2 address for given parameters
    /// @param bytecode The contract bytecode
    /// @param salt The salt for CREATE2
    /// @return addr The computed address
    function computeCreate2Address(bytes memory bytecode, bytes32 salt) public view returns (address addr) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        
        addr = address(uint160(uint256(hash)));
    }
}
