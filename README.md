## Kaia-Precompile-Toolkit

This toolkit demonstrates the integration of protocol native smart contracts in Kaia called Precompiles.

While there are a lot of protocol native smart contracts implemented in Kaia, this toolkit covers the integration of the following precompiles::

`**ecrecover(bytes32 hash,bytes32 sig)**`: The ecrecover precompile is both native to Ethereum and the Kaia protocol. It is used to recover the signer of a particular transaction or payload for verification purposes. When sending a transaction, there are some additional data you might want to pass in and to prevent man-in-the-middle attack or mempool-altering attack, you would want to send them in bytes and sign them with your privateKey, so before Kaia nodes agree to the state-changing transaction and the KLVM executing them, you would want the Kaia nodes to verify that the msg.sender or the owner of the transaction is the signer whose privateKey was used to sign the transaction.

In this case, it was used in a Library called SignUtils, to recover the signer. This is done by first constructing a messageHash using the hashing function keccak256 and additionally hash them to fit the Kaia signature scheme to get a digest which would be signed. The `**isValid**` function is used to check if the owner or signer ows the signature. It returns the recoverSigner function that recover the actual signer for comparison.

This Library is integrated into the NFTMarketplace contract, it takes in a struct parameter containing the signature of type bytes32, and it does a validation check using branching statements. 

`**ValidateSender**`: The ValidateSender precompile is used to validate the sender of a transaction, it works similarly to ecrecover but it returns either truthy or falsy when a sender is not the actual sender of a transaction. It is in the ValidSigner library and integrated with the ENS contract to validateSender. The sender has to construct a messageHash or a cryptographic digest of the message, it checks if the hash length is zero to confirm if a message was ever sent, and it checks if it returns true before updating the state and storing the message in the chat session.


`**sha256**`: In the same ValidSigner library of the ValidateSender precompile, the hashing algorithm used is sha256, which is another precompile used for hashing in cryptography.

`**vmLog**`: This precompile is used to log data to the, it's mapped to an address 0x3fd where it's stored, and using the address, we could make a low-level call to call the precompile to Log some messages.

## Usage

When integrating any of the precompile into your code, ensure to follow the steps taken, through the Library and others, as followed,
