const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("MarketPlace", () => {

    let owner, buyer1, buyer2, buyer3, buyer4, buyer5;
    let Tokens, tokens, MarketPlace, marketPlace;

    const uriLink = "";
    const initialSupply = 10**8;

    beforeEach(async () => {
        [owner, buyer1, buyer2, buyer3, buyer4, buyer5] = await ethers.getSigners();
        // Deploy tokens contract.
        Tokens = await ethers.getContractFactory("Tokens");
        tokens = await Tokens.deploy(
            uriLink,
            initialSupply
        );
        await tokens.deployed();

        // Deploy MarketPlace contract.
        MarketPlace = await ethers.getContractFactory("MarketPlace");
        marketPlace = await MarketPlace.deploy(tokens.address);
        marketPlace.deployed();

        // Claim BlazeTokens from other accounts.
        await tokens.connect(buyer1).claimBlazeTokens();
        await tokens.connect(buyer2).claimBlazeTokens();
        await tokens.connect(buyer3).claimBlazeTokens();
        await tokens.connect(buyer4).claimBlazeTokens();
        await tokens.connect(buyer5).claimBlazeTokens();

        // Give the marketPlace contract permission to handle ERC1155 tokens.
        await tokens.setApprovalForAll(marketPlace.address, true);
        await tokens.connect(buyer1).setApprovalForAll(marketPlace.address, true);
        await tokens.connect(buyer2).setApprovalForAll(marketPlace.address, true);
        await tokens.connect(buyer3).setApprovalForAll(marketPlace.address, true);
        await tokens.connect(buyer4).setApprovalForAll(marketPlace.address, true);
        await tokens.connect(buyer5).setApprovalForAll(marketPlace.address, true);
    });

    it("Users can list a NFT for sale.", async() => {
        // Mint an NFT with owner address and list it for sale.
        await tokens.mintNFT();
        expect(await tokens.balanceOf(owner.address, 1)).to.equal(1);
        
        await marketPlace.listNFT(1, 1000, 30);

        // Check changes in storage variables.
        const listing1 = await marketPlace.nftListings(1);
        expect(listing1.seller).to.be.equal(owner.address);
        expect(listing1.price).to.be.equal(1000);
        expect(listing1.isListed).to.be.equal(true);
        expect(await marketPlace.tokenOwnersWithRoyalties(1, 0)).to.be.equal(owner.address);
        expect(await marketPlace.tokenOwnersRoyaltyPercentage(1, 0)).to.be.equal(30);

    });

    it("Users can buy listed NFTs and previous owners receive royalties.", async() => {
        // Mint an NFT with owner address and list it for sale.
        await tokens.mintNFT();
        expect(await tokens.balanceOf(owner.address, 1)).to.equal(1);
        await marketPlace.listNFT(1, 1000, 30);

        // Check changes in storage variables.
        const listing1 = await marketPlace.nftListings(1);
        expect(listing1.seller).to.be.equal(owner.address);
        expect(listing1.price).to.be.equal(1000);
        expect(listing1.isListed).to.be.equal(true);
        expect(await marketPlace.tokenOwnersWithRoyalties(1, 0)).to.be.equal(owner.address);
        expect(await marketPlace.tokenOwnersRoyaltyPercentage(1, 0)).to.be.equal(30);

        // --------------------------------------------------------------------------------------

        // Buy the listed NFT with buyer1 address.
        expect(await tokens.balanceOf(buyer1.address, 1)).to.equal(0);
        await marketPlace.connect(buyer1).buyNFT(1);
        expect(await tokens.balanceOf(buyer1.address, 1)).to.equal(1);
        // Check whether NFT got removed from sale after purchase.
        const listingAfterSale1 = await marketPlace.nftListings(1);
        expect(listingAfterSale1.isListed).to.be.equal(false);

        // --------------------------------------------------------------------------------------

        // List the NFT with buyer1 as seller.
        await marketPlace.connect(buyer1).listNFT(1, 2000, 10);

        // Check changes in storage variables.
        const listing2 = await marketPlace.nftListings(1);
        expect(listing2.seller).to.be.equal(buyer1.address);
        expect(listing2.price).to.be.equal(2000);
        expect(listing2.isListed).to.be.equal(true);
        expect(await marketPlace.tokenOwnersWithRoyalties(1, 1)).to.be.equal(buyer1.address);
        expect(await marketPlace.tokenOwnersRoyaltyPercentage(1, 1)).to.be.equal(10);

        // --------------------------------------------------------------------------------------

        // Buy the NFT listed by buyer1 with buyer2 address.
        expect(await tokens.balanceOf(buyer2.address, 1)).to.equal(0);
        await marketPlace.connect(buyer2).buyNFT(1);
        expect(await tokens.balanceOf(buyer2.address, 1)).to.equal(1);
        // Check whether NFT got removed from sale after purchase.
        const listingAfterSale2 = await marketPlace.nftListings(1);
        expect(listingAfterSale2.isListed).to.be.equal(false);

        // --------------------------------------------------------------------------------------

        // List NFT with buyer2 address and set royaltyPercentage to 0.
        // Check that buyer2 address did not get added to tokenOwnersWithRoyalties() array
        // but correctly got set as seller address.

        // Arrays before listing.
        const ownersArrayBeforeListing = await marketPlace.getTokenOwners(1);
        const royaltyArrayBeforeListing = await marketPlace.getTokenOwnersRoyaltyPercentage(1);

        await marketPlace.connect(buyer2).listNFT(1, 5000, 0);
        // Check changes in storage variables.
        const listing3 = await marketPlace.nftListings(1);
        expect(listing3.seller).to.be.equal(buyer2.address);
        expect(listing3.price).to.be.equal(5000);
        expect(listing3.isListed).to.be.equal(true);

        // Arrays after listing.
        const ownersArrayAfterListing = await marketPlace.getTokenOwners(1);
        const royaltyArrayAfterListing = await marketPlace.getTokenOwnersRoyaltyPercentage(1);
        
        // Length of both arrays should be same before and after listing.
        expect(ownersArrayBeforeListing.length).to.be.equal(ownersArrayAfterListing.length);
        expect(royaltyArrayBeforeListing.length).to.be.equal(royaltyArrayAfterListing.length);

        // --------------------------------------------------------------------------------------

        // Buy NFT listed by buyer2 with buyer3 address.
        // Check whether marketPlace fees was collected.
        // Also check whether previous owners => owner and buyer1 got their respective royalties.
        // And the seller => buyer2 got listing price after reductions.
        
        // Balances before NFT is purchased.
        const marketPlaceBalanceBeforePurchase = await tokens.balanceOf(marketPlace.address, 0);
        const ownerBalanceBeforePurchase = await tokens.balanceOf(owner.address, 0);
        const buyer1BalanceBeforePurchase = await tokens.balanceOf(buyer1.address, 0);
        const buyer2BalanceBeforePurchase = await tokens.balanceOf(buyer2.address, 0);

        // Buy the NFT.
        expect(await tokens.balanceOf(buyer3.address, 1)).to.equal(0);
        await marketPlace.connect(buyer3).buyNFT(1);
        expect(await tokens.balanceOf(buyer3.address, 1)).to.equal(1);
        // Check whether NFT got removed from sale after purchase.
        const listingAfterSale3 = await marketPlace.nftListings(1);
        expect(listingAfterSale3.isListed).to.be.equal(false);

        // Calculate how much tokens were to be received by each address.
        const marketPlaceTokens = (25 * 5000) / 1000;  // 2.5% of listing price
        const ownerTokens = (30 * 5000) / 100; // 30% royalty
        const buyer1Tokens = (10 * 5000) / 100; // 10% royalty
        // buyer2 will receive salePrice - reductions.
        const buyer2Tokens = 5000 - marketPlaceTokens - ownerTokens - buyer1Tokens;

        // Balances after NFT is purchased.
        const marketPlaceBalanceAfterPurchase = await tokens.balanceOf(marketPlace.address, 0);
        const ownerBalanceAfterPurchase = await tokens.balanceOf(owner.address, 0);
        const buyer1BalanceAfterPurchase = await tokens.balanceOf(buyer1.address, 0);
        const buyer2BalanceAfterPurchase = await tokens.balanceOf(buyer2.address, 0);
        
        // Check whether the balances got incremented by calculated amounts or not.
        expect(marketPlaceBalanceAfterPurchase).to.be.equal(+marketPlaceBalanceBeforePurchase + +marketPlaceTokens);
        expect(ownerBalanceAfterPurchase).to.be.equal(+ownerBalanceBeforePurchase + +ownerTokens);
        expect(buyer1BalanceAfterPurchase).to.be.equal(+buyer1BalanceBeforePurchase + +buyer1Tokens);
        expect(buyer2BalanceAfterPurchase).to.be.equal(+buyer2BalanceBeforePurchase + +buyer2Tokens);

    });

});
