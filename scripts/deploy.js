const { ethers } = require("hardhat");

async function main() {
    // Deploy the Tokens contract
    const uriLink = "";
    const initialSupply = 10**8;
    const Tokens = await ethers.getContractFactory("Tokens");
    const tokens = await Tokens.deploy(
        uriLink,
        initialSupply
    );
    await tokens.deployed();
    console.log("Tokens contract deployed at: ", tokens.address);

    // Deploy the MarketPlace contract.
    const MarketPlace = await ethers.getContractFactory("MarketPlace");
    const marketPlace = await MarketPlace.deploy(tokens.address);
    await marketPlace.deployed();
    console.log("MarketPlace contract is deployed at: ", marketPlace.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.log(error);
        process.exit(1);
    })
