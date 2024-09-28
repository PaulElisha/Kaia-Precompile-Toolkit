// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importing a library for validating signers
import "./Lib/ValidSigner.sol";

contract ENS {
    // Custom errors for improved gas efficiency and clarity
    error InvalidSender(); // Thrown when the sender is not valid
    error InvalidMessage(); // Thrown when the message is invalid
    error NoTipSent(); // Thrown when the expected tip amount is not sent

    // Event emitted when a message is successfully sent
    event MessageSent(
        address indexed sender, // The address of the sender
        address indexed receiver, // The address of the receiver
        bytes32 indexed msgHash // The hash of the message
    );

    // Struct to represent a message
    struct Message {
        address name; // Address of the sender
        string message; // The content of the message
        uint256 messageId; // Unique identifier for the message
        uint48 timeStamp; // Timestamp of when the message was sent
        address to; // Address of the intended recipient
    }

    uint256 msgId = 0; // Counter for unique message IDs

    // Mapping to store messages by their ID
    mapping(uint256 => Message) public messages;

    // Mapping to store chat history as an array of messages by their ID
    mapping(uint256 => Message[]) public chat;

    /**
     * @dev Function to send a message from one user to another.
     * @param m The message struct containing details about the message.
     * @param _to The address of the intended recipient.
     * @param amount The amount of Ether to send as a tip.
     * @param signature The signature used to validate the sender.
     * @return result A boolean indicating success or failure.
     */
    function sendMessage(
        Message calldata m,
        address _to,
        uint256 amount,
        bytes memory signature
    ) public payable returns (bool result) {
        // Hashing the message using sha256 precompile for validation
        bytes32 messageHash = sha256(abi.encode(m));

        // ValidateSender precompile used to validate that the sender is authorized
        result = SignUtils.ValidateSender(msg.sender, messageHash, signature);

        if (!result) revert InvalidSender(); // Revert if sender validation fails
        if (messageHash.length == 0) revert InvalidMessage(); // Revert if the message hash is invalid

        // Store the new message in storage
        Message storage message = messages[msgId];
        message.name = msg.sender; // Set sender's address
        message.message = m.message; // Set the actual message content
        message.messageId = msgId; // Assign a unique ID to this message
        message.timeStamp = uint48(block.timestamp); // Record the current timestamp
        message.to = _to; // Set recipient's address

        chat[msgId].push(message); // Add this message to the chat history

        if (msg.value != amount) revert NoTipSent(); // Ensure that the correct tip amount is sent

        payable(_to).transfer(amount); // Transfer the tip amount to the recipient

        emit MessageSent(msg.sender, _to, messageHash); // Emit an event indicating that a message was sent

        return true; // Indicate success
    }
}
