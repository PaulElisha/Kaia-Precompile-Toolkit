// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FeePayerContract {
    function feePayer() internal returns (address addr) {
        assembly {
            let freemem := mload(0x40)
            let start_addr := add(freemem, 12)

            if iszero(call(gas(), 0x3fe, 0, 0, 0, start_addr, 20)) {
                invalid()
            }

            addr := mload(freemem)
        }
    }

    function getFeePayer() public returns (address) {
        address feePayerAddress = feePayer();
        return feePayerAddress;
    }
}
