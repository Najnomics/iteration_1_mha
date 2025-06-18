// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {MultiHookAdapter} from "../MultiHookAdapter.sol";
import {PermissionedMultiHookAdapter} from "../PermissionedMultiHookAdapter.sol";

/// @title DeploymentLibrary
/// @notice Library for common deployment operations
library DeploymentLibrary {
    
    /// @notice Error thrown when deployment parameters are invalid
    error InvalidDeploymentParameters();
    
    /// @notice Validate deployment parameters
    /// @param poolManager Pool manager address
    /// @param defaultFee Default fee value
    function validateParameters(IPoolManager poolManager, uint24 defaultFee) internal pure {
        if (address(poolManager) == address(0)) revert InvalidDeploymentParameters();
        if (defaultFee > 1_000_000) revert InvalidDeploymentParameters(); // Max 100%
    }
    
    /// @notice Validate permissioned deployment parameters
    /// @param poolManager Pool manager address  
    /// @param defaultFee Default fee value
    /// @param governance Governance address
    /// @param hookManager Hook manager address
    /// @param enableHookManagement Whether hook management is enabled
    function validatePermissionedParameters(
        IPoolManager poolManager,
        uint24 defaultFee,
        address governance,
        address hookManager,
        bool enableHookManagement
    ) internal pure {
        validateParameters(poolManager, defaultFee);
        if (governance == address(0)) revert InvalidDeploymentParameters();
        if (enableHookManagement && hookManager == address(0)) revert InvalidDeploymentParameters();
    }
    
    /// @notice Deploy contract using CREATE2
    /// @param bytecode Contract bytecode
    /// @param salt Deployment salt
    /// @return addr Deployed contract address
    function deployWithCreate2(bytes memory bytecode, bytes32 salt) internal returns (address addr) {
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(addr) { revert(0, 0) }
        }
    }
    
    /// @notice Compute CREATE2 address
    /// @param bytecode Contract bytecode  
    /// @param salt Deployment salt
    /// @param deployer Deployer address
    /// @return addr Computed address
    function computeCreate2Address(
        bytes memory bytecode, 
        bytes32 salt,
        address deployer
    ) internal pure returns (address addr) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                deployer,
                salt,
                keccak256(bytecode)
            )
        );
        addr = address(uint160(uint256(hash)));
    }
    
    /// @notice Generate MultiHookAdapter bytecode
    /// @param poolManager Pool manager address
    /// @param defaultFee Default fee value
    /// @return bytecode Contract bytecode
    function getMultiHookAdapterBytecode(
        IPoolManager poolManager,
        uint24 defaultFee
    ) internal pure returns (bytes memory bytecode) {
        bytecode = abi.encodePacked(
            type(MultiHookAdapter).creationCode,
            abi.encode(poolManager, defaultFee)
        );
    }
    
    /// @notice Generate PermissionedMultiHookAdapter bytecode
    /// @param poolManager Pool manager address
    /// @param defaultFee Default fee value
    /// @param governance Governance address
    /// @param hookManager Hook manager address
    /// @param enableHookManagement Whether hook management is enabled
    /// @return bytecode Contract bytecode
    function getPermissionedMultiHookAdapterBytecode(
        IPoolManager poolManager,
        uint24 defaultFee,
        address governance,
        address hookManager,
        bool enableHookManagement
    ) internal pure returns (bytes memory bytecode) {
        bytecode = abi.encodePacked(
            type(PermissionedMultiHookAdapter).creationCode,
            abi.encode(poolManager, defaultFee, governance, hookManager, enableHookManagement)
        );
    }
}