// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Library for handling signature verification and message hashing
library SignUtils {
    /**
     * @dev Constructs a message hash from the provided parameters.
     * @param _token The address of the token contract.
     * @param _tokenId The ID of the token being listed.
     * @param _price The price at which the token is listed.
     * @param _deadline The deadline by which the listing is valid.
     * @param _seller The address of the seller.
     * @return bytes32 The constructed message hash.
     */
    function constructMessageHash(
        address _token,
        uint256 _tokenId,
        uint256 _price,
        uint88 _deadline,
        address _seller
    ) public pure returns (bytes32) {
        // Create a hash of the concatenated parameters using keccak256
        return
            keccak256(
                abi.encodePacked(_token, _tokenId, _price, _deadline, _seller)
            );
    }

    /**
     * @dev Validates if a given signature corresponds to a message hash signed by a specific signer.
     * @param messageHash The hash of the message that was signed.
     * @param signature The signature to verify.
     * @param signer The address expected to be the signer.
     * @return bool True if the signature is valid; otherwise, false.
     */
    function isValid(
        bytes32 messageHash,
        bytes memory signature,
        address signer
    ) internal pure returns (bool) {
        // Get the Ethereum signed message hash from the original message hash
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        // Recover the signer from the signature and compare with the expected signer
        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    /**
     * @dev Gets the Ethereum signed message hash for a given message hash.
     * This is used to prefix messages with a standard format before signing.
     * @param messageHash The original message hash.
     * @return bytes32 The Ethereum signed message hash.
     */
    function getEthSignedMessageHash(
        bytes32 messageHash
    ) internal pure returns (bytes32) {
        // Prefix the message with "\x19Ethereum Signed Message:\n32" and hash it again
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }

    /**
     * @dev Recovers the signer address from a given Ethereum signed message hash and signature.
     * @param ethSignedMessageHash The Ethereum signed message hash.
     * @param signature The signature used to verify the signer.
     * @return address The recovered signer address.
     */
    function recoverSigner(
        bytes32 ethSignedMessageHash,
        bytes memory signature
    ) internal pure returns (address) {
        // Split the signature into its components (r, s, v)
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        // Use ecrecover to get the address that signed the message
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    /**
     * @dev Splits a signature into its components: r, s, and v.
     * @param sig The signature to split.
     * @return r The r component of the signature.
     * @return s The s component of the signature.
     * @return v The recovery byte of the signature (0 or 1).
     */
    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        // Ensure that the length of the signature is valid (65 bytes)
        require(sig.length == 65, "Invalid signature length");

        assembly {
            // Load r, s, and v from the signature byte array using assembly for efficiency
            r := mload(add(sig, 32)) // r starts at offset 32
            s := mload(add(sig, 64)) // s starts at offset 64
            v := byte(0, mload(add(sig, 96))) // v starts at offset 96
        } // implicitly return (r, s, v)
    }
}
