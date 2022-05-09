// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract Tokens is ERC1155 {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private constant BlazeToken = 0;

    mapping(address => bool) private hasClaimedTokens;

    constructor(
        string memory _uriLink,
        uint256 _tokenInitialSupply
    ) ERC1155(_uriLink) {
        _mint(msg.sender, BlazeToken, _tokenInitialSupply, "");
    }

    function claimBlazeTokens() external {
        require(
            hasClaimedTokens[msg.sender] == false,
            "Tokens: You have already claimed your share of tokens."
        );
        _mint(msg.sender, BlazeToken, 50000, "");
        hasClaimedTokens[msg.sender] = true;
    }

    function mintNFT() external {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId, 1, "");
    }
}
