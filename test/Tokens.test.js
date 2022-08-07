const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Tokens", () => {

    let owner;
    let buyer1;
    let buyer2;
    let buyer3;

    let Tokens;
    let tokens;

    const uriLink = "";
    const initialSupply = 10**8;

    beforeEach(async () => {
        [owner, buyer1, buyer2, buyer3] = await ethers.getSigners();
        Tokens = await ethers.getContractFactory("Tokens");
        tokens = await Tokens.deploy(
            uriLink,
            initialSupply
        );
        await tokens.deployed();
    });

    it("Mints correct initial supply of BlazeToken to owner.", async () => {
        const ownerBalance = await tokens.balanceOf(
            owner.address,
            0
        );
        expect(ownerBalance).to.equal(initialSupply);
    });

    it("Other users can claim tokens only once.", async () => {
        // Claim tokens.
        await tokens.connect(buyer1).claimBlazeTokens();
        expect(await tokens.balanceOf(buyer1.address, 0))
            .to.equal(50000);

        // Now try again to claim tokens.
        expect(
            tokens.connect(buyer1).claimBlazeTokens()
        ).to.be.revertedWith("Tokens: You have already claimed your share of tokens.");
    });

    it("Users can mint NFTs.", async () => {
        await tokens.connect(buyer1).mintNFT();
        expect(await tokens.balanceOf(buyer1.address, 1))
            .to.equal(1);
        
        await tokens.connect(buyer2).mintNFT();
        expect(await tokens.balanceOf(buyer2.address, 2))
            .to.equal(1);

        await tokens.connect(buyer3).mintNFT();
        expect(await tokens.balanceOf(buyer3.address, 3))
            .to.equal(1);
    });
});
 