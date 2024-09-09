// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

error Logger__VMLoggerCallFailed();

contract Logger {
    function callVmLog(bytes memory str) private {
        (bool success, ) = address(0x3fd).call(str);
        if (!success) revert Logger__VMLoggerCallFailed();
    }

    function logMessage(string memory message) public {
        callVmLog(abi.encodePacked(message));
    }
}
