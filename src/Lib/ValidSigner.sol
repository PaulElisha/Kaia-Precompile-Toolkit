// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Library for handling signature validation and sender verification
library SignUtils {
    /**
     * @dev Validates that a message was signed by a specific sender.
     * This function checks the provided signatures against the message hash and sender's address.
     * @param sender The address of the expected signer.
     * @param msgHash The hash of the message that was signed.
     * @param sigs The concatenated signatures to validate.
     * @return bool True if the signatures are valid for the given sender; otherwise, false.
     */
    function ValidateSender(
        address sender,
        bytes32 msgHash,
        bytes memory sigs
    ) public returns (bool) {
        // Ensure that the length of signatures is a multiple of 65 (each signature consists of r, s, v)
        require(sigs.length % 65 == 0, "Invalid signature length");

        // Create a new bytes array to hold the combined data for validation
        bytes memory data = new bytes(20 + 32 + sigs.length);
        uint idx = 0; // Index for filling the data array
        uint i;

        // Copy the sender address (20 bytes) into the data array
        for (i = 0; i < 20; i++) {
            data[idx++] = (bytes20(sender))[i];
        }

        // Copy the message hash (32 bytes) into the data array
        for (i = 0; i < 32; i++) {
            data[idx++] = msgHash[i];
        }

        // Append all signatures into the data array
        for (i = 0; i < sigs.length; i++) {
            data[idx++] = sigs[i];
        }

        assembly {
            // Use inline assembly to call an external contract at address 0x3ff
            let ptr := add(data, 0x20) // Pointer to the data in memory (skipping length)

            // Attempt to call the external contract with gas and pass in the data
            if iszero(call(gas(), 0x3ff, 0, ptr, idx, 31, 1)) {
                // If the call fails, revert with an invalid opcode
                invalid()
            }
            // Return success status from this function (returning true)
            return(0, 32) // Return pointer to result in memory
        }
    }
}
