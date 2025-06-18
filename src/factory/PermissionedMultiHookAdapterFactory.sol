// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PermissionedMultiHookAdapter} from "../PermissionedMultiHookAdapter.sol";

/// @title PermissionedMultiHookAdapterFactory
/// @notice Factory for deploying PermissionedMultiHookAdapter instances
contract PermissionedMultiHookAdapterFactory {
    
    error InvalidParams();
    
    event PermissionedAdapterDeployed(address indexed adapter, address indexed poolManager, uint24 defaultFee, address indexed governance, address hookManager, address deployer);
    
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
    
    function predictPermissionedMultiHookAdapterAddress(
        IPoolManager poolManager,
        uint24 defaultFee,
        address governance,
        address hookManager,
        bool enableHookManagement,
        bytes32 salt
    ) external view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(
                type(PermissionedMultiHookAdapter).creationCode,
                abi.encode(poolManager, defaultFee, governance, hookManager, enableHookManagement)
            ))
        ));
        return address(uint160(uint256(hash)));
    }
}