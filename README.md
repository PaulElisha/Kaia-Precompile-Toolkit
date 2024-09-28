## Kaia-Precompile-Toolkit

This toolkit demonstrates the integration of protocol native smart contracts in Kaia called Precompiles.

While there are a lot of protocol native smart contracts implemented in Kaia, this toolkit covers the integration of the following precompiles::

`ecrecover(bytes32 hash,bytes32 sig)`: The ecrecover precompile is both native to Ethereum and the Kaia protocol. It is used to recover the signer of a particular transaction or payload for verification purposes. When sending a transaction, there are some additional data you might want to pass in and to prevent man-in-the-middle attack or mempool-altering attack, you would want to send them in bytes and sign them with your privateKey, so before Kaia nodes agree to the state-changing transaction and the KLVM executing them, you would want the Kaia nodes to verify that the msg.sender or the owner of the transaction is the signer whose privateKey was used to sign the transaction.

##  SignUtils Lib
In this case, it was used in a Library called SignUtils, to recover the signer. 
1. This is done by first constructing a messageHash using the hashing function keccak256 and additionally hash them to fit the Kaia signature scheme to get a digest which would be signed. 
2. The `**isValid**` function is used to check if the owner or signer ows the signature. 
3. It returns the recoverSigner function that recover the actual signer for comparison.

This Library is integrated into the NFTMarketplace contract, it takes in a struct parameter containing the signature of type bytes32, and it does a validation check using branching statements. 

### Applications of the ECDSA precompiled

As the ECDSA precompiled play an important role in guaranteeing security and preserving message/transaction integrity. 

The following are the use cases:

1. Validate Ownership - it is used in the NFT Marketplace contract to validate the owner of the Listing so that only the legitimate owner can create listing.
2. Identity verification - it can be used to verify that a user is the claimed sender of a message just by checking their address without exposing their keys.
3. Signature verification - it can be used to verify the signature on a particular message. 
4. Validating DeFi Transactions - DeFi involves a lot of monetary transactions, it is good to use ECDSA precompile to authorize users.
5. Secure messaging - it can be used to prevent all forms of attack, man-in-the-middle or replay attack.

`ValidateSender`: The ValidateSender precompile is used to validate the sender of a transaction, it works similarly to ecrecover but it returns either truthy or falsy when a sender is not the actual sender of a transaction.

## ValidSigner Lib

1. It is in the ValidSigner library and integrated with the ENS contract to validateSender. 
2. The sender has to construct a messageHash or a cryptographic digest of the message, 
3. it checks if the hash length is zero to confirm if a message was ever sent, 
4. and it checks if it returns true before updating the state and storing the message in the chat session.


`sha256`: In the same ValidSigner library of the ValidateSender precompile, the hashing algorithm used is sha256, which is another precompile used for hashing in cryptography.

## Applications of the SHA256 precompiled

1. Salting - it can be used to create a salt when using create2 to ensure that the address 
2. Transaction Hashing - it can be used to hash a transaction to get a unique identifier for each transactions, it helps to prevent transaction collision.
3. Randomness Generation - it can be used to generate random words for applications that leverages cryptography to ensure an unpredictable output, e.g. in the use of prediction games.
4. Signatures Generation - it can also be used to generate signatures.

## Usage

### Usage Steps
1. ecrecover(bytes32 hash, bytes32 sig)

`Construct a Message Hash:`
Use keccak256 to hash the relevant data (e.g., transaction details) to create a unique identifier.
text
bytes32 messageHash = keccak256(abi.encodePacked(data));

`Sign the Message:`
The user signs the message hash using their private key, producing a signature consisting of three components: r, s, and v.

`Recover Signer:`
Call the ecrecover function with the message hash and signature to retrieve the signer's address.
text
address signer = ecrecover(messageHash, v, r, s);

`Verify Ownership:`
bool isValid = ValidateSender(senderAddress, messageHash, signatures);


### Usage Steps

2. sha256
   
`Hash Input Data:`
Use SHA256 to hash any relevant data or messages.
bytes32 hashedData = sha256(abi.encodePacked(inputData));

```solidity
pragma solidity ^0.8.0;

import "./SignUtils.sol"; // Importing SignUtils library

contract ExampleContract {
    function verifySignature(bytes32 msgHash, bytes memory sig) public view returns (bool) {
        // Recover signer using ecrecover precompile
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(sig);
        address recoveredSigner = ecrecover(msgHash, v, r, s);
        
        // Check if recovered signer matches expected address
        return recoveredSigner == msg.sender;
    }

    function validateSender(address sender, bytes32 msgHash, bytes memory sigs) public view returns (bool) {
        return ValidateSender(sender, msgHash, sigs); // Validate sender using ValidateSender precompile
    }

    function getSHA256(bytes memory data) public pure returns (bytes32) {
        return sha256(data); // Hash input data using sha256 precompile
    }
}
```