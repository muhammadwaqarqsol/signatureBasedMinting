// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library rewardTypes{
    struct claimAmount{
        address owner; //Owner verifier
        address _user; // User address
        uint256 amount; //
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }
}