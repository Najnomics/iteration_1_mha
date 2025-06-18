// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {MultiHookAdapter} from "../MultiHookAdapter.sol";

/// @title MultiHookAdapterFactory
/// @notice Basic factory for deploying MultiHookAdapter instances
contract MultiHookAdapterFactory {
    
    error InvalidParams();
    
    event MultiHookAdapterDeployed(address indexed adapter, address indexed poolManager, uint24 defaultFee, address indexed deployer);
    
    function deployMultiHookAdapter(IPoolManager poolManager, uint24 defaultFee, bytes32 salt) external returns (address adapter) {
        if (address(poolManager) == address(0) || defaultFee > 1_000_000) revert InvalidParams();
        
        bytes memory bytecode = abi.encodePacked(type(MultiHookAdapter).creationCode, abi.encode(poolManager, defaultFee));
        
        assembly {
            adapter := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(adapter) { revert(0, 0) }
        }
        
        emit MultiHookAdapterDeployed(adapter, address(poolManager), defaultFee, msg.sender);
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
    
    function computeCreate2Address(bytes memory bytecode, bytes32 salt) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));
        return address(uint160(uint256(hash)));
    }
}