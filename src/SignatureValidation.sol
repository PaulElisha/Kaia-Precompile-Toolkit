// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib/ValidSigner.sol";

contract ENS {
    // The use of the ValidateSender precompile and the sha256 precompile
    // when sending an onchain message to validate that the message was signed by the sender

    error InvalidSender();
    error InvalidMessage();
    error NoTipSent();

    event MessageSent(
        address indexed sender,
        address indexed receiver,
        bytes32 indexed msgHash
    );

    struct Message {
        address name;
        string message;
        uint256 messageId;
        uint48 timeStamp;
        address to;
    }
    uint256 msgId = 0;

    mapping(uint256 id => Message) public messages;
    mapping(uint256 id => Message[]) public chat;

    function sendMessage(
        Message calldata m,
        address _to,
        uint256 amount,
        bytes memory signature
    ) public payable returns (bool result) {
        // sha256 hashing precompile
        bytes32 messageHash = sha256(abi.encode(m));

        // ValidateSender precompile used to validate the sender
        result = SignUtils.ValidateSender(msg.sender, messageHash, signature);

        if (!result) revert InvalidSender();
        if (messageHash.length == 0) revert InvalidMessage();

        Message storage message = messages[msgId];
        message.name = msg.sender;
        message.message = m.message;
        message.messageId = msgId;
        message.timeStamp = uint48(block.timestamp);
        message.to = _to;

        chat[msgId].push(message);

        if (msg.value != amount) revert NoTipSent();

        payable(_to).transfer(amount);

        emit MessageSent(msg.sender, _to, messageHash);
    }
}
