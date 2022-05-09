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
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.log(error);
        process.exit(1);
    })
