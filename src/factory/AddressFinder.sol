// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {DeploymentLibrary} from "./DeploymentLibrary.sol";

/// @title AddressFinder
/// @notice Library for finding specific addresses via CREATE2
library AddressFinder {
    
    /// @notice Find salt that produces target address
    /// @param bytecode Contract bytecode
    /// @param targetAddress Target address to match
    /// @param deployer Deployer address
    /// @param maxAttempts Maximum number of attempts
    /// @return salt The salt that produces target address
    /// @return found Whether a matching salt was found
    function findSaltForTarget(
        bytes memory bytecode,
        address targetAddress,
        address deployer,
        uint256 maxAttempts
    ) internal pure returns (bytes32 salt, bool found) {
        for (uint256 i = 0; i < maxAttempts; i++) {
            salt = bytes32(i);
            address predictedAddress = DeploymentLibrary.computeCreate2Address(
                bytecode, salt, deployer
            );
            
            if (predictedAddress == targetAddress) {
                return (salt, true);
            }
        }
        return (bytes32(0), false);
    }
}