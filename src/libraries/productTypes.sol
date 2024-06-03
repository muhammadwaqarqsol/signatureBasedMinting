// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
library productType{
    struct productListing{
        address owner; // address of product creator 
        uint256 price; // price of the product amount in lmv tokens
        string uri; // product uri 
    }

    struct productBuying{
        address productbuyer;
        address nft_contract;
        address nftOwner;
        uint256 price;
        uint256 nonce;
        uint8 v;
        bytes32 r;
        bytes s;
    }
}