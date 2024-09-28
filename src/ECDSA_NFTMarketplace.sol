// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Importing the ERC721 token standard from Solmate library
import "solmate/tokens/ERC721.sol";
// Importing utility functions for signature validation
import "./Lib/SignUtils.sol";

contract Marketplace {
    // Struct to represent a listing in the marketplace
    struct Listing {
        address token; // Address of the ERC721 token contract
        uint256 tokenId; // ID of the token being listed
        uint256 price; // Price for which the token is listed
        bytes sig; // Signature to validate the listing
        uint88 deadline; // Timestamp until when the listing is valid
        address lister; // Address of the user who created the listing
        bool active; // Indicates if the listing is currently active
    }

    // Mapping to store listings by their unique ID
    mapping(uint256 => Listing) public listings;

    address public admin; // Address of the contract admin
    uint256 public listingId; // Counter for unique listing IDs

    // Custom error messages for various revert conditions
    error NotOwner();
    error NotApproved();
    error MinPriceTooLow();
    error DeadlineTooSoon();
    error MinDurationNotMet();
    error InvalidSignature();
    error ListingNotExistent();
    error ListingNotActive();
    error PriceNotMet(int256 difference);
    error ListingExpired();
    error PriceMismatch(uint256 originalPrice);

    // Events to log significant actions in the marketplace
    event ListingCreated(uint256 indexed listingId, Listing);
    event ListingExecuted(uint256 indexed listingId, Listing);
    event ListingEdited(uint256 indexed listingId, Listing);

    // Constructor to set the admin address on deployment
    constructor() {
        admin = msg.sender;
    }

    /**
     * @dev Function to create a new listing in the marketplace.
     * @param l The listing details including token, tokenId, price, etc.
     * @return lId The unique ID of the created listing.
     */
    function createListing(Listing calldata l) public returns (uint256 lId) {
        // Ensure that the caller is the owner of the token being listed
        if (ERC721(l.token).ownerOf(l.tokenId) != msg.sender)
            revert NotApproved();

        // Ensure that this contract is approved to transfer tokens on behalf of the owner
        if (!ERC721(l.token).isApprovedForAll(msg.sender, address(this)))
            revert NotApproved();

        // Validate price and deadlines for creating a listing
        if (l.price < 0.01 ether) revert MinPriceTooLow(); // Minimum price check
        if (l.deadline < block.timestamp) revert DeadlineTooSoon(); // Deadline must be in the future
        if (l.deadline - block.timestamp < 60 minutes)
            revert MinDurationNotMet(); // Minimum duration between now and deadline

        // Assert signature validity using SignUtils library
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
                msg.sender // Validate that msg.sender signed this message
            )
        ) revert InvalidSignature();

        // Store new listing in storage using current listingId as key
        Listing storage li = listings[listingId];
        li.token = l.token;
        li.tokenId = l.tokenId;
        li.price = l.price;
        li.sig = l.sig;
        li.deadline = uint88(l.deadline);
        li.lister = msg.sender; // Set lister as msg.sender who created this listing
        li.active = true; // Mark this listing as active

        emit ListingCreated(listingId, l); // Emit event for new listing creation

        lId = listingId; // Return current listing ID as result
        listingId++; // Increment listing ID for next entry

        return lId; // Return unique ID of created listing
    }

    /**
     * @dev Function to execute a purchase of a listed token.
     * @param _listingId The ID of the listing to execute.
     */
    function executeListing(uint256 _listingId) public payable {
        if (_listingId >= listingId) revert ListingNotExistent(); // Check if listing exists

        Listing storage listing = listings[_listingId]; // Retrieve the specified listing

        if (listing.deadline < block.timestamp) revert ListingExpired(); // Check if listing is expired

        if (!listing.active) revert ListingNotActive(); // Ensure that the listing is active

        if (listing.price != msg.value)
            revert PriceNotMet(int256(listing.price) - int256(msg.value)); // Validate sent Ether matches price

        // Update state to mark this listing as inactive after execution
        listing.active = false;

        // Transfer ownership of the token from lister to buyer (msg.sender)
        ERC721(listing.token).transferFrom(
            listing.lister,
            msg.sender,
            listing.tokenId
        );

        // Transfer Ether payment to the original lister (the seller)
        payable(listing.lister).transfer(listing.price);

        emit ListingExecuted(_listingId, listing); // Emit event for successful execution of a listing
    }

    /**
     * @dev Function to edit an existing listing.
     * @param _listingId The ID of the existing listing.
     * @param _newPrice The new price for the token.
     * @param _active The new active status for this listing.
     */
    function editListing(
        uint256 _listingId,
        uint256 _newPrice,
        bool _active
    ) public {
        if (_listingId >= listingId) revert ListingNotExistent(); // Check if the specified listing exists

        Listing storage listing = listings[_listingId]; // Retrieve existing listing

        if (listing.lister != msg.sender) revert NotOwner(); // Ensure only owner can edit their own listings

        listing.price = _newPrice; // Update price for this listing
        listing.active = _active; // Update active status

        emit ListingEdited(_listingId, listing); // Emit event for editing a listing
    }

    /**
     * @dev Getter function to retrieve details about a specific listing.
     * @param _listingId The ID of the desired listing.
     * @return The details of the specified Listing struct.
     */
    function getListing(
        uint256 _listingId
    ) public view returns (Listing memory) {
        return listings[_listingId]; // Return details of specified listing from storage
    }
}
