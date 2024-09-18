// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";

contract Marketplace {
    struct Listing {
        address token;
        uint256 tokenId;
        uint256 price;
        bytes sig;
        // Slot 4
        uint88 deadline;
        address lister;
        bool active;
    }

    mapping(uint256 => Listing) public listings;
    address public admin;
    uint256 public listingId;

    /* ERRORS */
    error NotOwner();
    error NotApproved();
    // error AddressZero();
    // error NoCode();
    error MinPriceTooLow();
    error DeadlineTooSoon();
    error MinDurationNotMet();
    error InvalidSignature();
    error ListingNotExistent();
    error ListingNotActive();
    error PriceNotMet(int256 difference);
    error ListingExpired();
    error PriceMismatch(uint256 originalPrice);

    /* EVENTS */
    event ListingCreated(uint256 indexed listingId, Listing);
    event ListingExecuted(uint256 indexed listingId, Listing);
    event ListingEdited(uint256 indexed listingId, Listing);

    constructor() {
        admin = msg.sender;
    }

    function createListing(Listing calldata l) public returns (uint256 lId) {
        if (ERC721(l.token).ownerOf(l.tokenId) != msg.sender)
            revert NotApproved();
        if (!ERC721(l.token).isApprovedForAll(msg.sender, address(this)))
            revert NotApproved();
        // if (l.token == address(0)) revert AddressZero();
        // if (l.token.code.length == 0) revert NoCode();
        if (l.price < 0.01 ether) revert MinPriceTooLow();
        if (l.deadline < block.timestamp) revert DeadlineTooSoon();
        if (l.deadline - block.timestamp < 60 minutes)
            revert MinDurationNotMet();

        // Assert signature
        if (
            SignUtils.isValid(
                SignUtils.constructMessageHash(
                    l.token,
                    l.tokenId,
                    l.price,
                    l.deadline,
                    l.lister
                ),
                l.sig,
                msg.sender
            )
        ) revert InvalidSignature();

        // append to Storage
        Listing storage li = listings[listingId];
        li.token = l.token;
        li.tokenId = l.tokenId;
        li.price = l.price;
        li.sig = l.sig;
        li.deadline = uint88(l.deadline);
        li.lister = msg.sender;
        li.active = true;

        // Emit event
        emit ListingCreated(listingId, l);
        lId = listingId;
        listingId++;
        return lId;
    }

    function executeListing(uint256 _listingId) public payable {
        if (_listingId >= listingId) revert ListingNotExistent();
        Listing storage listing = listings[_listingId];
        if (listing.deadline < block.timestamp) revert ListingExpired();
        if (!listing.active) revert ListingNotActive();
        if (listing.price != msg.value)
            revert PriceNotMet(int256(listing.price) - int256(msg.value));

        // Update state
        listing.active = false;

        // transfer
        ERC721(listing.token).transferFrom(
            listing.lister,
            msg.sender,
            listing.tokenId
        );

        // transfer eth
        payable(listing.lister).transfer(listing.price);

        // Update storage
        emit ListingExecuted(_listingId, listing);
    }

    function editListing(
        uint256 _listingId,
        uint256 _newPrice,
        bool _active
    ) public {
        if (_listingId >= listingId) revert ListingNotExistent();
        Listing storage listing = listings[_listingId];
        if (listing.lister != msg.sender) revert NotOwner();
        listing.price = _newPrice;
        listing.active = _active;
        emit ListingEdited(_listingId, listing);
    }

    // add getter for listing
    function getListing(
        uint256 _listingId
    ) public view returns (Listing memory) {
        // if (_listingId >= listingId)
        return listings[_listingId];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library SignUtils {
    function constructMessageHash(
        address _token,
        uint256 _tokenId,
        uint256 _price,
        uint88 _deadline,
        address _seller
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_token, _tokenId));
    }

    function isValid(
        bytes32 messageHash,
        bytes memory signature,
        address signer
    ) internal pure returns (bool) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function getEthSignedMessageHash(
        bytes32 messageHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 ethSignedMessageHash,
        bytes memory signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        } // implicitly return (r, s, v)
    }
}
