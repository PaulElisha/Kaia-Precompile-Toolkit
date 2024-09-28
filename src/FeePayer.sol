// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FeePayerContract {
    /**
     * @dev Internal function to retrieve the fee payer address.
     * This function uses inline assembly to call an external contract
     * at a specific address (0x3fe) to obtain the fee payer's address.
     * @return addr The address of the fee payer.
     */
    function feePayer() internal returns (address addr) {
        assembly {
            // Load the free memory pointer into freemem
            let freemem := mload(0x40)
            // Define a starting address for storing the result
            let start_addr := add(freemem, 12)

            // Call the external contract at address 0x3fe with no input data
            // and store the result at start_addr. The call uses all available gas.
            if iszero(call(gas(), 0x3fe, 0, 0, 0, start_addr, 20)) {
                // If the call fails, revert the transaction
                invalid()
            }

            // Load the value from memory where the fee payer address was stored
            addr := mload(freemem)
        }
    }

    /**
     * @dev Public function to get the fee payer's address.
     * Calls the internal feePayer function and returns its result.
     * @return The address of the fee payer.
     */
    function getFeePayer() public returns (address) {
        // Call the internal feePayer function to retrieve the fee payer address
        address feePayerAddress = feePayer();
        return feePayerAddress; // Return the retrieved address
    }
}
