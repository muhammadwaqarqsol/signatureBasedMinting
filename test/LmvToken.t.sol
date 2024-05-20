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

    bytes32 public constant makeClaim_TypeHash=keccak256(
        "ClaimAmount(address Owner,address _user,uint256 amount,uint256 nonce)"
    );
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
        takeSignature(_earnToken.owner(),userone, 2, 1,makeClaim_TypeHash);
        vm.stopPrank();
        vm.startPrank(userone);
        _earnToken.mint(tempReward, userone);
        vm.stopPrank();
        console.log("user balance", _earnToken.balanceOf(userone));
    }

    function test_SignatureMint_butSomeoneElseClaim() public {
        vm.prank(_earnToken.owner());
        takeSignature(_earnToken.owner(),address(1), 2, 1,makeClaim_TypeHash);
        vm.stopPrank();
        vm.startPrank(userone);
        bytes4 selector = bytes4(keccak256("UnAuthorized()"));
        vm.expectRevert(selector);
        _earnToken.mint(tempReward, userone);
        vm.stopPrank();
        console.log("user balance", _earnToken.balanceOf(userone));
    }

     function test_SignatureMint_but_signatureisnotfromOwner() public {
        vm.prank(address(1));
        takeSignature(address(1),userone, 2, 1,makeClaim_TypeHash);
        vm.stopPrank();
        vm.startPrank(userone);
        bytes4 selector = bytes4(keccak256("InValidSignature()"));
        vm.expectRevert(selector);
        _earnToken.mint(tempReward, userone);
        vm.stopPrank();
        console.log("user balance", _earnToken.balanceOf(userone));
    }

    function test_SignatureMint_but_ClaimingsameAmountAgain() public {
        vm.prank(_earnToken.owner());
        takeSignature(_earnToken.owner(),userone, 2, 1,makeClaim_TypeHash);
        vm.stopPrank();
        vm.startPrank(userone);
        _earnToken.mint(tempReward, userone);
        bytes4 selector = bytes4(keccak256("AlreadyExecuted()"));
        vm.expectRevert(selector);
        _earnToken.mint(tempReward, userone);
        vm.stopPrank();
        console.log("user balance", _earnToken.balanceOf(userone));
    }

    function test_SignatureMint_but_ClaimingwithZeroAddress() public {
        vm.prank(_earnToken.owner());
        takeSignature(_earnToken.owner(),address(0), 2, 1,makeClaim_TypeHash);
        vm.stopPrank();
        vm.startPrank(address(0));
        bytes4 selector = bytes4(keccak256("ZeroAddress()"));
        vm.expectRevert(selector);
        _earnToken.mint(tempReward, address(0));
        vm.stopPrank();
        console.log("user balance", _earnToken.balanceOf(userone));
    }



    function test_SignatureMint_but_SenderisZeroAddress() public {
        vm.prank(_earnToken.owner());
        takeSignature(_earnToken.owner(),userone, 2, 1,makeClaim_TypeHash);
        vm.stopPrank();
        vm.startPrank(address(0));
        bytes4 selector = bytes4(keccak256("ZeroAddress()"));
        vm.expectRevert(selector);
        _earnToken.mint(tempReward, userone);
        vm.stopPrank();
        console.log("user balance", _earnToken.balanceOf(userone));
    }
    function takeSignature(
        address _owner,
        address _user,
        uint256 amount,
        uint256 nonce,
        bytes32 orderhash
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

        bytes32 digest = getTypedDataHash(makeClaim,orderhash);
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
        rewardTypes.claimAmount memory makeClaim,
        bytes32 orderhash
    ) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash(),
                getStructHash(makeClaim,orderhash)
            )
        );
    }

    function getStructHash(
        rewardTypes.claimAmount memory makeClaim,
        bytes32 orderhash
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                orderhash,
                makeClaim.owner,
                makeClaim._user,
                makeClaim.amount,
                makeClaim.nonce
            )
        );
    }
}
