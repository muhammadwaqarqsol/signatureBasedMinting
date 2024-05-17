// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./NFT.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {rewardTypes} from "./libraries/rewardTypes.sol";
error InValidSignature();
error claimNotForYou();
contract LMVToken is ERC20,EIP712,Ownable,ReentrancyGuard {
    using rewardTypes for rewardTypes.claimAmount;
    constructor() ERC20("Let's Move", "LMV") Ownable(msg.sender)EIP712("Let'sMove","1") {
    }

    enum Action{
        SignUp
    }

    
    function mint(rewardTypes.claimAmount calldata claim,address _to) public nonReentrant{
        bool isVerified;
        isVerified=executeIfSignatureMatch(claim, uint8(Action.SignUp));
        if (!isVerified){
            revert InValidSignature();
        }
        if(!(claim._user==_to)){
            revert claimNotForYou();
        }
        _mint(_to, claim.amount * 10 ** 18);
    }

    function domainHash() internal view returns (bytes32) {
    bytes32 hash = keccak256(
        abi.encode(
            keccak256(
                "EIP712Domain(string name,string version,address verifyingContract)"
            ),
            keccak256(bytes("Let'sMove")),
            keccak256(bytes("1")),
            address(this)  // Change to address(this) to match LMVToken
        )
    );
    return hash;
}

    
    function executeIfSignatureMatch(
        rewardTypes.claimAmount calldata claim,
        uint8 actionChoice
    )internal view returns(bool){
        bytes32 eip712DomainHash=domainHash();
        bytes32 hashStruct;
        if(actionChoice==0){
            hashStruct=generateHashforSignUp(owner(), claim._user, claim.amount,claim.nonce);
        }
        bytes32 hash=keccak256(
            abi.encodePacked("\x19\x01",eip712DomainHash,hashStruct)
        );

        address signer=ecrecover(hash, claim.v, claim.r, claim.s);

        if(!(signer==owner())){
            revert InValidSignature();
        }

        if(signer==address(0)){
            revert InValidSignature();
        }
        return true;
    }

    function generateHashforSignUp(address _owner,address _to,uint256 _amount,uint _nonce) internal pure returns(bytes32){
        bytes32 hashStruct=keccak256(
        abi.encode(keccak256("ClaimAmount(address Owner,address _user,uint256 amount,uint256 nonce)"),
        _owner,
        _to,
        _amount,
        _nonce
        )
        );
        return hashStruct;
    }

}