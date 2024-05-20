// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

import "./NFT.sol";
import {rewardTypes} from "./libraries/rewardTypes.sol";

error InValidSignature();
error UnAuthorized();
error AlreadyExecuted();
error ZeroAddress();
error Failed();
error ZeroAmount();
error ZeroEntryFee();
error NotActive();
error NotEnoughBalance();
error ApprovalRequired();
error NotInChallenge();

contract LMVToken is ERC20,EIP712,Ownable,ReentrancyGuard {
    

    using rewardTypes for rewardTypes.claimAmount;
    //event for ClaimAmount
    event ClaimedAmount(address indexed user, uint256 amount);

    //event for challenge
    event ChallengeCreated(uint256 indexed challengeId, address indexed creator, uint256 entryFee, uint256 nftId);
    event ParticipantEntered(uint256 indexed challengeId,address indexed user);
    event challengeWinner(uint256 indexed challengeId, address indexed winner, uint256 totalPool);

    NFT public ChallengeNFT;
    uint256 public ChallengeCounter;

    //Mapping for claim amount
    mapping(address => mapping(uint256 => bool)) private _isUserClaimNonceExecuted;


    //mapping for Challenge 
    mapping (uint256 => uint256) public challengeEntryFee;
    mapping (uint256 => uint256) public challengeTotalPool;
    mapping (uint256 => bool)    public challengeActive;
    mapping (uint256 => mapping(address=>bool)) public challengeParticipants;
    
    
    constructor(address nftAddress) ERC20("Let's Move", "LMV") Ownable(msg.sender)EIP712("Let'sMove","1") {
            ChallengeCounter=0;
            ChallengeNFT = NFT(nftAddress); 
    }

    
    function mint(rewardTypes.claimAmount calldata claim,address _to) public nonReentrant{
        if(msg.sender==address(0)){
            revert ZeroAddress();
        }
        if(_isUserClaimNonceExecuted[claim._user][claim.nonce]){
            revert AlreadyExecuted();
        }
        bool isVerified;
        isVerified=executeIfSignatureMatch(claim);
        if (!isVerified){
            revert InValidSignature();
        }
        if(claim._user==address(0)){
            revert ZeroAddress();
        }
        if(claim.amount==0){
            revert ZeroAmount();
        }
        if(!(claim._user==_to)){
            revert UnAuthorized();
        }
        _isUserClaimNonceExecuted[claim._user][claim.nonce]=true;
        _mint(_to, claim.amount * 10 ** 18);
        emit ClaimedAmount(claim._user, claim.amount);
    }

    function createChallenge(uint256 entryFee,string memory tokenUri,address user)public nonReentrant{
        if(msg.sender==address(0) || user==address(0)){
            revert ZeroAddress();
        }
        if(!(entryFee>0)){
            revert ZeroEntryFee();
        }
        ChallengeNFT.createToken(tokenUri,user);
        ChallengeCounter+=1;
        challengeEntryFee[ChallengeCounter]=entryFee*10**18;
        challengeTotalPool[ChallengeCounter]=0;
        challengeActive[ChallengeCounter]=true;

        emit ChallengeCreated(ChallengeCounter,user,entryFee,ChallengeCounter);

    }



    function enterChallenge(uint256 challengeId)public nonReentrant{
        if(msg.sender==address(0)){
            revert ZeroAddress();
        }
        if(!(challengeActive[challengeId])){
            revert NotActive();
        }
        if(!(balanceOf(msg.sender)>=challengeEntryFee[challengeId])){
            revert NotEnoughBalance();
        }
        transfer(address(this), challengeEntryFee[challengeId]);
        challengeParticipants[challengeId][msg.sender]=true;
        challengeTotalPool[challengeId]+=challengeEntryFee[challengeId];
        emit ParticipantEntered(challengeId, msg.sender);
    }


    function concludeChallenge(uint256 challengeId,rewardTypes.claimAmount calldata claim)public nonReentrant{
        if(msg.sender==address(0)){
            revert ZeroAddress();
        }
        if(!(challengeActive[challengeId])){
            revert NotActive();
        }
        if(!(challengeParticipants[challengeId][claim._user])){
            revert NotInChallenge();
        }
        if(_isUserClaimNonceExecuted[claim._user][claim.nonce]){
            revert AlreadyExecuted();
        }
        bool isVerified;
        isVerified=executeIfSignatureMatch(claim);
         if (!isVerified){
            revert InValidSignature();
        }
        if(claim._user==address(0)){
            revert ZeroAddress();
        }
        if(claim.amount==0){
            revert ZeroAmount();
        }
        if(!(claim._user==msg.sender)){
            revert UnAuthorized();
        }
        if(!(ChallengeNFT.getApproved(challengeId)==address(this))){
            revert ApprovalRequired();
        }
        challengeActive[challengeId]=false;
        _isUserClaimNonceExecuted[claim._user][claim.nonce]=true;
        _transfer(address(this), claim._user, challengeTotalPool[challengeId]);
        ChallengeNFT.safeTransferFrom(ChallengeNFT.ownerOf(challengeId), claim._user, challengeId);
        emit challengeWinner(challengeId,claim._user,challengeTotalPool[challengeId]);
        challengeTotalPool[challengeId]=0;
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

    
    function executeIfSignatureMatch(rewardTypes.claimAmount calldata claim)internal view returns(bool){
        bytes32 eip712DomainHash=domainHash();
        
        bytes32 hashStruct;
        
        hashStruct=generateHashForClaim(owner(), claim._user, claim.amount,claim.nonce);
        
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

    function generateHashForClaim(address _owner,address _to,uint256 _amount,uint _nonce) internal pure returns(bytes32){
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