// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SignUtils {
    function ValidateSender(
        address sender,
        bytes32 msgHash,
        bytes memory sigs
    ) public returns (bool) {
        require(sigs.length % 65 == 0, "Invalid signature length");
        bytes memory data = new bytes(20 + 32 + sigs.length);
        uint idx = 0;
        uint i;

        for (i = 0; i < 20; i++) {
            data[idx++] = (bytes20(sender))[i];
        }
        for (i = 0; i < 32; i++) {
            data[idx++] = msgHash[i];
        }
        for (i = 0; i < sigs.length; i++) {
            data[idx++] = sigs[i];
        }
        assembly {
            let ptr := add(data, 0x20)
            if iszero(call(gas(), 0x3ff, 0, ptr, idx, 31, 1)) {
                invalid()
            }
            return(0, 32)
        }
    }
}
