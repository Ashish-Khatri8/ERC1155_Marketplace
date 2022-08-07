# ERC1155 MarketPlace

## Contract: Tokens.sol

- Contract deployed on [rinkeby test network](https://rinkeby.etherscan.io/address/0xb89ABc0d1eDaE155A387023Ed0AdB1698D3aF469) at:

> 0xb89ABc0d1eDaE155A387023Ed0AdB1698D3aF469

- Takes URI String for tokens and tokenInitialSupply to mint to owner as arguments.
- This contract mints ERC1155 tokens with the following details.

### TokenId: 0 (BlazeToken)

- This token will be used to buy the NFTs listed on marketplace.
- The owner of this contract gets 10**8 => 100 million tokens minted at the time of deployment.
- Any account can interact with claimBlazeTokens() function only once, which will mint 50,000 tokens to that account.
- This token does not have any decimal places.

### NFTs

- Any address can interact with mintNFT() function to mint a NFT with incrementing token ids.
- Token IDs start with 1 and increment for next token(implemented using Counters.sol).
- These NFT tokens can be listed for sale on the MarketPlace contract for a specific amount of BlazeTokens(TokenId: 0)

## Contract: MarketPlace.sol

- A marketplace contract where users can list their minted ERC1155 NFTs(from the Tokens.sol contract) for sale, which then could be purchased by other users with ERC1155 BlazeTokens => TokenId: 0 (Tokens.sol).

- NFT owner can set a royalty percentage between 0 and 30%.

- Platform fees is 2.5%.

- Only the contract owner can interact with the claimPlatformEarnings() function to collect the platform fees accumulated so far in the contract.

- Before listing NFTs, user will need to give the MarketPlace contract approval for all ERC1155 tokens, by interacting with setApprovalForAll() function of Tokens.sol contract, where arguments to be passed are:

```shell
operator: address of MarketPlace contract
approved: true
```

- Contract Address: 0x03bBFf7C9912C0a1960a36B18fc38c7492B6EA30

- Contract deployed on [rinkeby test network](https://rinkeby.etherscan.io/address/0x03bBFf7C9912C0a1960a36B18fc38c7492B6EA30).

### Basic Sample Hardhat Project

This project demonstrates a basic Hardhat use case.

```shell
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```
