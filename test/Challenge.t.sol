// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {rewardTypes} from "../src/libraries/rewardTypes.sol";

import "../src/LetsMove.sol";
import "forge-std/console.sol";
import "../src/NFT.sol";
contract RewardToken is Test {
    using rewardTypes for rewardTypes.claimAmount;
    NFT public nft_contract;
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
        nft_contract= new NFT();
        _earnToken = new LMVToken(address(nft_contract));
        vm.stopPrank();
    }

    function test_owner() public view{
        assertEq(_earnToken.owner(), creator, "not an Owner error.....");
    }

    function test_createChallenge()public{
     vm.startPrank(userone);
     _earnToken.createChallenge(5,"abc",userone);
     vm.stopPrank();

     assert(_earnToken.challengeActive(1)==true);
    assert(_earnToken.challengeEntryFee(1)==5*10**18);
    assert(_earnToken.ChallengeCounter()==1);
    assert(_earnToken.challengeTotalPool(1)==0);
    assert(nft_contract.ownerOf(1)==userone);

    }

  function test_createChallenge_thenEnterParticipant()public{
     vm.startPrank(userone);
     _earnToken.createChallenge(5,"abc",userone);
     vm.stopPrank();

    vm.prank(_earnToken.owner());
    takeSignature(_earnToken.owner(),address(1), 5, 1,makeClaim_TypeHash);
    vm.stopPrank();
    vm.startPrank(address(1));
    _earnToken.mint(tempReward, address(1));
    vm.stopPrank();
    console.log("user balance", _earnToken.balanceOf(address(1)));

    vm.startPrank(address(1));
    _earnToken.enterChallenge(1);
    vm.stopPrank();
    console.log("user balance", _earnToken.balanceOf(address(1)));
  
  }
  

    function test_createChallenge_thenEnterParticipant_declareWinner() public{
     vm.startPrank(userone);
     _earnToken.createChallenge(5,"abc",userone);
     nft_contract.approve(address(_earnToken),1);
     vm.stopPrank();

    vm.prank(_earnToken.owner());
    takeSignature(_earnToken.owner(),address(1), 5, 1,makeClaim_TypeHash);
    vm.stopPrank();
    vm.startPrank(address(1));
    _earnToken.mint(tempReward, address(1));
    vm.stopPrank();
    console.log("user balance", _earnToken.balanceOf(address(1)));

    vm.startPrank(address(1));
    _earnToken.enterChallenge(1);
    vm.stopPrank();
    console.log("user balance", _earnToken.balanceOf(address(1)));

    vm.prank(_earnToken.owner());
    takeSignature(_earnToken.owner(),address(2), 5, 1,makeClaim_TypeHash);
    vm.stopPrank();
    vm.startPrank(address(2));
    _earnToken.mint(tempReward, address(2));
    vm.stopPrank();
    console.log("user balance", _earnToken.balanceOf(address(2)));

    vm.startPrank(address(2));
    _earnToken.enterChallenge(1);
    vm.stopPrank();
    console.log("user balance", _earnToken.balanceOf(address(2)));
    
    vm.prank(_earnToken.owner());
    takeSignature(_earnToken.owner(),address(2), _earnToken.challengeTotalPool(1), 3,makeClaim_TypeHash);
    vm.stopPrank();

    vm.startPrank(address(2));
    _earnToken.concludeChallenge(1, tempReward);
    vm.stopPrank();

    console.log("NFT",_earnToken.balanceOf(address(2)),"NFT",nft_contract.balanceOf(address(2)));
  }


  function test_createChallenge_zeroEntryFee()public{
    vm.startPrank(address(1));
    bytes4 selector = bytes4(keccak256("ZeroEntryFee()"));
    vm.expectRevert(selector);
    _earnToken.createChallenge(0,"abc",address(1));
    vm.stopPrank();
  }



  function test_createChallenge_zeroAddress_sender()public{
    vm.startPrank(address(0));
    bytes4 selector = bytes4(keccak256("ZeroAddress()"));
    vm.expectRevert(selector);
    _earnToken.createChallenge(3,"abc",address(0));
    vm.stopPrank();
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
