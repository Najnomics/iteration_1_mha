// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {MultiHookAdapter} from "../MultiHookAdapter.sol";

/// @title HookAddressFactory
/// @notice Factory for deploying adapters to specific hook addresses
contract HookAddressFactory {
    
    error InvalidParams();
    
    event MultiHookAdapterDeployed(address indexed adapter, address indexed poolManager, uint24 defaultFee, address indexed deployer);
    
    function deployToHookAddress(IPoolManager poolManager, uint24 defaultFee, address targetAddress) external returns (address adapter) {
        if (address(poolManager) == address(0) || defaultFee > 1_000_000) revert InvalidParams();
        
        bytes32 bytecodeHash = keccak256(abi.encodePacked(type(MultiHookAdapter).creationCode, abi.encode(poolManager, defaultFee)));
        
        for (uint256 i = 0; i < 1000; i++) {
            bytes32 salt = bytes32(i);
            bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash));
            
            if (address(uint160(uint256(hash))) == targetAddress) {
                bytes memory bytecode = abi.encodePacked(type(MultiHookAdapter).creationCode, abi.encode(poolManager, defaultFee));
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
}