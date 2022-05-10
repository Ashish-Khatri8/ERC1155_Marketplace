const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("MarketPlace", () => {

    let owner;
    let buyer1;
    let buyer2;
    let buyer3;

    let Tokens;
    let tokens;

    let MarketPlace;
    let marketPlace;

    const uriLink = "";
    const initialSupply = 10**8;

    beforeEach(async () => {
        [owner, buyer1, buyer2, buyer3] = await ethers.getSigners();
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

        // Give the marketPlace contract permission to handle ERC1155 tokens.
        await tokens.setApprovalForAll(marketPlace.address, true);
        await tokens.connect(buyer1).setApprovalForAll(marketPlace.address, true);
        await tokens.connect(buyer2).setApprovalForAll(marketPlace.address, true);
        await tokens.connect(buyer3).setApprovalForAll(marketPlace.address, true);
    });

    it("Users can list a NFT for sale.", async() => {
        // Mint an NFT with owner address and list it for sale.
        await tokens.mintNFT();
        expect(await tokens.balanceOf(owner.address, 1)).to.equal(1);
        
        await marketPlace.listNFT(1, 1000, 30);
        const listingDetails1 = await marketPlace.listingDetails(1);
        expect(listingDetails1[1].addr).to.be.equal(owner.address);

        // Mint an NFT with another address and list it for sale.
        await tokens.connect(buyer1).mintNFT();
        expect(await tokens.balanceOf(buyer1.address, 2)).to.equal(1);

        await marketPlace.connect(buyer1).listNFT(2, 10000, 20);
        const listingDetails2 = await marketPlace.listingDetails(2);
        expect(listingDetails2[1].addr).to.be.equal(buyer1.address);

    });

    it("Other users can buy the listed NFTs.", async() => {
        // Mint an NFT with owner address and list it for sale.
        await tokens.mintNFT();
        expect(await tokens.balanceOf(owner.address, 1)).to.equal(1);
        await marketPlace.listNFT(1, 1000, 30);

        // Buy the listed NFT with another address.
        expect(await tokens.balanceOf(buyer2.address, 1)).to.equal(0);
        await marketPlace.connect(buyer2).buyNFT(1);
        expect(await tokens.balanceOf(buyer2.address, 1)).to.equal(1);
    });

});
