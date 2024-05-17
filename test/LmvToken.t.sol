// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {rewardTypes} from "../src/libraries/rewardTypes.sol";
import "../src/LetsMove.sol";
import "forge-std/console.sol";

contract RewardToken is Test {
    using rewardTypes for rewardTypes.claimAmount;

    LMVToken public _earnToken;

    uint256 internal createPrivateKey;
    address internal creator;

    uint256 internal useronePrivateKey;
    address internal userone;

    rewardTypes.claimAmount public tempReward;

    function setUp() public {
        createPrivateKey = 0xA11CE;
        creator = vm.addr(createPrivateKey);

        useronePrivateKey = 0xB0B;
        userone = vm.addr(useronePrivateKey);
        vm.startPrank(creator);
        _earnToken = new LMVToken();
        vm.stopPrank();
    }

    function test_owner() public view{
        assertEq(_earnToken.owner(), creator, "not an Owner error.....");
    }

    function test_SignatureMint() public {
        vm.prank(_earnToken.owner());
        takeSignature(_earnToken.owner(),userone, 2, 1);
        vm.stopPrank();

        
        vm.startPrank(userone);
        _earnToken.mint(tempReward, userone);
        vm.stopPrank();
        console.log("user balance", _earnToken.balanceOf(userone));
    }

    function takeSignature(
        address _owner,
        address _user,
        uint256 amount,
        uint256 nonce
    ) public returns (uint8 v, bytes32 r, bytes32 s) {
        rewardTypes.claimAmount memory makeClaim = rewardTypes.claimAmount(
            _owner,
            _user,
            amount,
            nonce,
            0,
            0x00,
            0x00
        );

        bytes32 digest = getTypedDataHash(makeClaim);
        (v, r, s) = vm.sign(createPrivateKey, digest);
        makeClaim.v = v;
        makeClaim.r = r;
        makeClaim.s = s;
        tempReward = makeClaim;
    }

    function domainHash() internal view returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,address verifyingContract)"
                ),
                keccak256(bytes("Let'sMove")),
                keccak256(bytes("1")),
                address(_earnToken)
            )
        );
        return hash;
    }

    function getTypedDataHash(
        rewardTypes.claimAmount memory makeClaim
    ) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash(),
                getStructHash(makeClaim)
            )
        );
    }

    function getStructHash(
        rewardTypes.claimAmount memory makeClaim
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                makeClaim.owner,
                makeClaim._user,
                makeClaim.amount,
                makeClaim.nonce
            )
        );
    }
}
