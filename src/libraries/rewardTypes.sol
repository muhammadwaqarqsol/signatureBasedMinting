// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library rewardTypes{
    struct claimAmount{
        address owner; //Owner verifier
        address _user; // User address to whom reward is assigned
        uint256 amount; // amount to claim / mint
        uint256 nonce; // order nonce (must be unique unless new claim)
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct ProductList{
        address owner; // address of product creator 
        uint256 price; // price of the product amount in lmv tokens
        string uri; // product uri 
    }

    struct ProductBuyer{
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