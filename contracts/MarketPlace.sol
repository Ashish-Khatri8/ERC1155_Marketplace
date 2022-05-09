// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";


contract MarketPlace is Ownable, ReentrancyGuard, ERC1155Holder {
    IERC1155 private tokensContract;
    uint256 private constant blazeToken = 0;

    struct NFT_Owner {
        address payable addr;
        uint256 royaltyPercentage;
    }

    struct NFT_Listing {
        NFT_Owner previousOwner;
        NFT_Owner owner;
        address payable seller;
        uint256 tokenId;
        uint256 price;
        bool isListed;
    }

    // Mapping tokenIds to NFT listings.
    mapping(uint256 => NFT_Listing) private nftListings;

    event NFT_Listed(
        address indexed by,
        uint256 indexed tokenId,
        uint256 price
    );

    event NFT_Sold(
        address indexed by,
        address indexed to,
        uint256 indexed tokenId,
        uint256 price
    );

    constructor(IERC1155 _tokenContractAddress) {
        require(
            address(_tokenContractAddress) != address(0),
            "MarketPlace: Tokens contract cannot be at null address."
        );
        tokensContract = _tokenContractAddress;
    }

    function collectPlatformEarnings() external onlyOwner {
        uint256 contractBalance = tokensContract.balanceOf(address(this), blazeToken);
        require(
            contractBalance > 0,
            "MarketPlace: No earnings available to be claimed!"
        );
        tokensContract.safeTransferFrom(
            address(this),
            owner(),
            blazeToken,
            contractBalance,
            ""
        );
    }

    function listingDetails(
        uint256 _tokenId
    ) external view returns(NFT_Listing memory) {
        return nftListings[_tokenId];
    }

    function listNFT(
        uint256 _tokenId,
        uint256 _price,
        uint256 _royaltyPercentage
    ) external {
        preListingValidation(_tokenId, _price, _royaltyPercentage);

        // Update new owner.
        nftListings[_tokenId].owner.addr = payable(msg.sender);
        nftListings[_tokenId].owner.royaltyPercentage = _royaltyPercentage;

        // Create new nft item.
        NFT_Listing memory newItem = NFT_Listing(
            nftListings[_tokenId].previousOwner,
            nftListings[_tokenId].owner,
            payable(msg.sender),
            _tokenId,
            _price,
            true
        );

        // List the new item.
        nftListings[_tokenId] = newItem;
        // Emit the NFT_Listed event.
        emit NFT_Listed(
            msg.sender,
            _tokenId,
            _price
        );
    }

    function buyNFT(uint256 _tokenId) external payable {
        preSaleValidation(_tokenId);
        NFT_Owner memory ownerBeforeSale = nftListings[_tokenId].owner;

        uint256 nftPrice = nftListings[_tokenId].price;
        makeTokenPayments(_tokenId, nftPrice);

        // Transfer NFT to the buyer.
        tokensContract.safeTransferFrom(
            nftListings[_tokenId].owner.addr,
            msg.sender,
            _tokenId,
            1,
            ""
        );

        // Remove NFT from listing
        nftListings[_tokenId].isListed = false;

        // Update the NFT owner.
        nftListings[_tokenId].previousOwner = ownerBeforeSale;
        nftListings[_tokenId].owner.addr = payable(msg.sender);

        // Emit the NFT_Sold event.
        emit NFT_Sold(
            nftListings[_tokenId].seller,
            msg.sender,
            _tokenId,
            nftPrice
        );
    }

    function makeTokenPayments(
        uint256 _tokenId,
        uint256 _nftPrice
    ) private nonReentrant {
        // Calculate royalties and platform fees.
        uint256 platformFees = (25 * _nftPrice) / 1000; // 2.5%

        // Royalties for previous owner.
        uint256 royalties = (
            nftListings[_tokenId].previousOwner.royaltyPercentage * _nftPrice
        ) / 100;
        
        // NFT sell price after reductions.
        uint256 updatedPrice = _nftPrice - platformFees - royalties;

        // Transfer updated sell price to current NFT owner.
        tokensContract.safeTransferFrom(
            msg.sender,
            nftListings[_tokenId].owner.addr,
            blazeToken,
            updatedPrice,
            ""
        );

        // Transfer royalties to previous NFT owner.
        if (
            nftListings[_tokenId].previousOwner.addr != address(0) &&
            royalties > 0
        ) {
            tokensContract.safeTransferFrom(
                msg.sender,
                nftListings[_tokenId].previousOwner.addr,
                blazeToken,
                royalties,
                ""
            );
        }

        // Transfer platform fees to the contract.
        tokensContract.safeTransferFrom(
            msg.sender,
            address(this),
            blazeToken,
            platformFees,
            ""
        );
    }

    function preListingValidation (
        uint256 _tokenId,
        uint256 _price,
        uint256 _royaltyPercentage
    ) private view {
        require(
            _tokenId != 0,
            "MarketPlace: Cannot list the BlazeToken for sale."
        );
        require(
            tokensContract.balanceOf(msg.sender, _tokenId) > 0,
            "MarketPlace: You are not authorized to list this NFT."
        );
        require(
            nftListings[_tokenId].isListed == false,
            "MarketPlace: NFT is already listed for sale."
        );
        require(
            _price > 0,
            "MarketPlace: NFT price must be greater than 0."
        );
        require(
            _royaltyPercentage >= 0 &&
            _royaltyPercentage < 31,
            "MarketPlace: Royalty Percentage must be between 0 and 30%."
        );
    }

    function preSaleValidation(uint256 _tokenId) private view {
        require(
            nftListings[_tokenId].isListed == true,
            "MarketPlace: NFT with given id is not available for sale."
        );
        require(
            nftListings[_tokenId].owner.addr != msg.sender,
            "MarketPlace: Cannot buy your own NFT."
        );
        require(
            tokensContract.isApprovedForAll(msg.sender, address(this)) &&
            tokensContract.balanceOf(msg.sender, blazeToken) >= nftListings[_tokenId].price,
            "MarketPlace: Unsufficient token allowance."
        );
    }
}
