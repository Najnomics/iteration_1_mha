// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {MultiHookAdapter} from "../MultiHookAdapter.sol";
import {PermissionedMultiHookAdapterFactory} from "./PermissionedMultiHookAdapterFactory.sol";
import {HookAddressFactory} from "./HookAddressFactory.sol";

/// @title MultiHookAdapterFactory
/// @notice Main factory for deploying MultiHookAdapter instances
contract MultiHookAdapterFactory {
    
    error InvalidParams();
    
    PermissionedMultiHookAdapterFactory public immutable permissionedFactory;
    HookAddressFactory public immutable hookAddressFactory;
    
    event MultiHookAdapterDeployed(address indexed adapter, address indexed poolManager, uint24 defaultFee, address indexed deployer);
    
    constructor() {
        permissionedFactory = new PermissionedMultiHookAdapterFactory();
        hookAddressFactory = new HookAddressFactory();
    }
    
    function deployMultiHookAdapter(IPoolManager poolManager, uint24 defaultFee, bytes32 salt) external returns (address adapter) {
        if (address(poolManager) == address(0) || defaultFee > 1_000_000) revert InvalidParams();
        
        bytes memory bytecode = abi.encodePacked(type(MultiHookAdapter).creationCode, abi.encode(poolManager, defaultFee));
        
        assembly {
            adapter := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(adapter) { revert(0, 0) }
        }
        
        emit MultiHookAdapterDeployed(adapter, address(poolManager), defaultFee, msg.sender);
    }
    
    function deployPermissionedMultiHookAdapter(
        IPoolManager poolManager,
        uint24 defaultFee,
        address governance,
        address hookManager,
        bool enableHookManagement,
        bytes32 salt
    ) external returns (address adapter) {
        return permissionedFactory.deployPermissionedMultiHookAdapter(
            poolManager, defaultFee, governance, hookManager, enableHookManagement, salt
        );
    }
    
    function deployToHookAddress(IPoolManager poolManager, uint24 defaultFee, address targetAddress) external returns (address adapter) {
        return hookAddressFactory.deployToHookAddress(poolManager, defaultFee, targetAddress);
    }
    
    function predictMultiHookAdapterAddress(IPoolManager poolManager, uint24 defaultFee, bytes32 salt) external view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(type(MultiHookAdapter).creationCode, abi.encode(poolManager, defaultFee)))
        ));
        return address(uint160(uint256(hash)));
    }
    
    function predictPermissionedMultiHookAdapterAddress(
        IPoolManager poolManager,
        uint24 defaultFee,
        address governance,
        address hookManager,
        bool enableHookManagement,
        bytes32 salt
    ) external view returns (address) {
        return permissionedFactory.predictPermissionedMultiHookAdapterAddress(
            poolManager, defaultFee, governance, hookManager, enableHookManagement, salt
        );
    }
    
    function computeCreate2Address(bytes memory bytecode, bytes32 salt) public view returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))))));
    }
}