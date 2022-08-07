// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";


/// @title ERC1155 MarketPlace
/// @author Ashish Khatri
contract MarketPlace is Ownable, ReentrancyGuard, ERC1155Holder {

    /// @dev ERC1155 tokens contract.
    IERC1155 private tokensContract;

    /// @dev It is the id of fungible ERC1155 token which will
    /// be used to buy the non-fungible ERC1155 tokens.
    uint256 private constant blazeTokenId = 0;

    struct NFT_Listing {
        address seller;
        uint256 price;
        bool isListed;
    }

    // Mapping tokenIds to NFT listings.
    mapping(uint256 => NFT_Listing) public nftListings;

    // Mapping tokenIds to an array of addresses(token owners who have set royaltyPercentage > 0)
    mapping(uint256 => address[]) public tokenOwnersWithRoyalties;

    // Mapping tokenIds to an array of royaltyPercentages set by token owners. 
    mapping(uint256 => uint256[]) public tokenOwnersRoyaltyPercentage;


    /// @dev Event to emit when an ERC1155 token is listed for sale.
    event NFT_Listed(
        address indexed by,
        uint256 indexed tokenId,
        uint256 price
    );

    /// @dev Event to emit when an ERC1155 token listed for sale is bought by someone.
    event NFT_Sold(
        address indexed by,
        address indexed to,
        uint256 indexed tokenId,
        uint256 price
    );

    /// @dev Event to emit when platform earnings are collected by the contract owner.
    event PlatformEarningsCollected(
        address indexed by,
        uint256 indexed tokenId,
        uint256 indexed amount
    );


    constructor(IERC1155 _tokenContractAddress) {
        require(
            address(_tokenContractAddress) != address(0),
            "MarketPlace: Tokens contract cannot be at null address."
        );
        tokensContract = _tokenContractAddress;
    }


    /**
        @dev Before listing a token for sale, makes sure that :
            - User is not trying to list the fungible ERC1155 token with id 0.
            - Sale Price for listing is greater than 0.
            - Royalty percentage is between 0 to 30 %
        @param _tokenId Id of the ERC1155 token to be listed for sale.
        @param _price Price set by user for token listing.
        @param _royaltyPercentage Royalty percentage set by user.
    */  
    modifier preListingValidation (
        uint256 _tokenId,
        uint256 _price,
        uint256 _royaltyPercentage
    ) {
        require(
            _tokenId != 0,
            "MarketPlace: Cannot list the BlazeToken for sale."
        );
        require(
            tokensContract.balanceOf(msg.sender, _tokenId) > 0,
            "MarketPlace: You are not authorized to list this NFT."
        );
        require(
            tokensContract.isApprovedForAll(msg.sender, address(this)),
            "MarketPlace: Insufficient token allowance."
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
        _;
    }

    /**
        @dev Before selling a token, makes sure that: 
            - Token with given id is listed for sale
            - User is not trying to buy token listed by themselves.
            - Buyer has provided enough allowance to this contract for buying the token.
        @param _tokenId Id the the ERC1155 token that the buyer wants to buy.
    */
    modifier preSaleValidation(uint256 _tokenId) {
        require(
            nftListings[_tokenId].isListed == true,
            "MarketPlace: NFT with given id is not available for sale."
        );
        require(
            nftListings[_tokenId].seller != msg.sender,
            "MarketPlace: Cannot buy your own NFT."
        );
        require(
            tokensContract.isApprovedForAll(msg.sender, address(this)) &&
            tokensContract.balanceOf(msg.sender, blazeTokenId) >= nftListings[_tokenId].price,
            "MarketPlace: Insufficient token allowance."
        );
        _;
    }


    /**
        @notice Returns all addresses of particular tokenId's owners with royalties > 0.
        @dev Returns an array of addresses which are owners of an NFT with provided id and royalty > 0.
        @param _tokenId Id of the ERC1155 token.
        @return An array of addresses, which are a token's owners with royaltyPercentage > 0.
    */
    function getTokenOwners(uint256 _tokenId) external view returns(address[] memory) {
        return tokenOwnersWithRoyalties[_tokenId];
    }

    /**
        @notice Returns all royaltyPercentages set by particular tokenId's owners.
        @dev Returns an uint array with royalty percentages of NFT owners with provided id.
        @param _tokenId Id of the ERC1155 token.
        @return An array of uint numbers, which are royaltyPercentages set by NFT owners..
    */
    function getTokenOwnersRoyaltyPercentage(uint256 _tokenId) external view returns(uint[] memory) {
        return tokenOwnersRoyaltyPercentage[_tokenId];
    }


    /**
        @notice Owner can call this function to collect the platform earnings. 
        @dev Checks contract balance before sending tokens.
    */
    function collectPlatformEarnings() external onlyOwner {
        uint256 contractBlazeTokenBalance = tokensContract.balanceOf(address(this), blazeTokenId);
        require(
            contractBlazeTokenBalance > 0,
            "MarketPlace: No earnings available to be claimed!"
        );

        // Emit the PlatformEarningsCollected() event.
        emit PlatformEarningsCollected(owner(), blazeTokenId, contractBlazeTokenBalance);

        // Transfer the platform earnings to the owner.
        tokensContract.safeTransferFrom(
            address(this),
            owner(),
            blazeTokenId,
            contractBlazeTokenBalance,
            ""
        );
    }


    /** 
        @notice Lists the token with given id, price and royalty percentage for sale.
        @dev Lists token with provided id, price and royaltyPercentage for sale.
        @param _tokenId Id of ERC1155 token to list for sale.
        @param _price Sale price for listed token.
        @param _royaltyPercentage Royalty percentage set by owner of token.
    */
    function listNFT(
        uint256 _tokenId,
        uint256 _price,
        uint256 _royaltyPercentage
    ) external preListingValidation(_tokenId, _price, _royaltyPercentage) {

        // Store address and royalty percentage in arrays only when _royaltyPercentage > 0.
        if (_royaltyPercentage > 0) {
            tokenOwnersWithRoyalties[_tokenId].push(msg.sender);
            tokenOwnersRoyaltyPercentage[_tokenId].push(_royaltyPercentage);
        }
        
        // Transfer the ERC1155 token from seller to itself before listing it for sale.
        tokensContract.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            1,
            ""
        );
        
        // Create new nft item.
        NFT_Listing memory newItem = NFT_Listing(
            msg.sender,
            _price,
            true
        );
        nftListings[_tokenId] = newItem;

        // Emit the NFT_Listed event.
        emit NFT_Listed(
            msg.sender,
            _tokenId,
            _price
        );
    }


    /** 
        @notice Function for buying a listed token.
        @dev This function is used to buy an ERC1155 token with the fungible ERC1155 token.
        @param _tokenId Id of the ERC1155 token user wants to buy.
    */
    function buyNFT(uint256 _tokenId) external payable preSaleValidation(_tokenId) {

        // Remove NFT from listing
        nftListings[_tokenId].isListed = false;
        
        // Charge buyer for platformFees, previous owner royalties and NFT sale price
        // in the fungible ERC1155 token with id 0 => blazeToken
        _makeBlazeTokenPayments(_tokenId, nftListings[_tokenId].price);

        // Emit the NFT_Sold event.
        emit NFT_Sold(
            tokenOwnersWithRoyalties[_tokenId][tokenOwnersWithRoyalties[_tokenId].length - 1],
            msg.sender,
            _tokenId,
            nftListings[_tokenId].price
        );

        // Transfer NFT to the buyer.
        tokensContract.safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            1,
            ""
        );
    }
    

    /** 
        @dev Handles transfer of ERC1155 fungible tokens with id 0 (blazeToken) for:
            - Buyer to Seller -> Listing price
            - Buyer to Previous Owners -> Royalties
            - Buyer to Marketplace(this) contract -> Marketplace fees.
    */
    function _makeBlazeTokenPayments(
        uint256 _tokenId,
        uint256 _nftPrice
    ) internal nonReentrant {

        // Calculate platform fees and transfer it to this contract from buyer.
        tokensContract.safeTransferFrom(
            msg.sender,
            address(this),
            blazeTokenId,
            (25 * _nftPrice) / 1000, //2.5% 
            ""
        );

        // Calculate royalties for all previous owners and send it to them from buyer.
        uint256 totalRoyalties;
        
        // Loop over the array of previous owners with royalties to send them their respective royalties.
        for(uint i=0; i < tokenOwnersWithRoyalties[_tokenId].length; i++) {
            
            // Don't give royalty to current seller.
            if (tokenOwnersWithRoyalties[_tokenId][i] != nftListings[_tokenId].seller) {
                
                // Increment totalRoyalties.
                totalRoyalties += ((tokenOwnersRoyaltyPercentage[_tokenId][i] * _nftPrice) / 100);

                // Transfer royalties.
                tokensContract.safeTransferFrom(
                    msg.sender,
                    tokenOwnersWithRoyalties[_tokenId][i],
                    blazeTokenId,
                    (tokenOwnersRoyaltyPercentage[_tokenId][i] * _nftPrice) / 100,
                    ""
                );
            }
        }
        
        // Subtract royalties and platform fees from listing price and send remaining amount to token seller from the buyer.
        tokensContract.safeTransferFrom(
            msg.sender,
            nftListings[_tokenId].seller,
            blazeTokenId,
            _nftPrice - totalRoyalties - ((25 * _nftPrice) / 1000),
            ""
        );
    }
 
}
