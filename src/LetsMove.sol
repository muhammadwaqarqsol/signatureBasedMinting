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
    
    /**
     * Using the rewardTypes library for the claimAmount struct.
     * Declares an event for ClaimAmount.
     */
    using rewardTypes for rewardTypes.claimAmount;

    
    /**
    * @dev Event emitted when a specific amount is claimed by a user.
    * @param user The address of the user who claimed the amount.
    * @param amount The amount that was claimed.
    */
    event ClaimedAmount(address indexed user, uint256 amount);

    
    /**
     * Event emitted when a challenge is created with the specified details.
     * @param challengeId The ID of the challenge created.
     * @param creator The address of the creator of the challenge.
     * @param entryFee The entry fee required for the challenge.
     * @param nftId The ID of the NFT associated with the challenge.
     */
    event ChallengeCreated(uint256 indexed challengeId, address indexed creator, uint256 entryFee, uint256 nftId);
    
    /** 
     * Event emitted when a participant enters a challenge with the specified details.
     * @param challengeId The ID of the challenge entered by the participant.
     * @param user The address of the participant who entered the challenge.
     */
    event ParticipantEntered(uint256 indexed challengeId,address indexed user);
    
    /**
    * Event emitted when a challenge winner is declared with the challenge ID, winner's address, and the total pool amount won.
    @param challengeId The ID of the winning challenge.
    @param winner The winner address of user who won that challenge.
    @param totalPool The total price pool of the challenge.
    */
    event challengeWinner(uint256 indexed challengeId, address indexed winner, uint256 totalPool);
    
    /**
     * Public variable to store the ChallengeNFT contract instance.
     */
    NFT public ChallengeNFT;

    /**
     * @notice Public variable to store the ChallengeCounter value.
     */
    uint256 public ChallengeCounter;

    //Mapping for claim amount nonce. Stopping the signature for being double use
    mapping(address => mapping(uint256 => bool)) private _isUserClaimNonceExecuted;


    //mapping for Challenge Fee set during challenge creation
    mapping (uint256 => uint256) public challengeEntryFee;
    //mapping for total entry fee submitted by participants to the pool
    mapping (uint256 => uint256) public challengeTotalPool;
    //mapping for Maintaining active challenge
    mapping (uint256 => bool)    public challengeActive;
    //mapping for maintaining the challenge participants in the particular challange
    mapping (uint256 => mapping(address=>bool)) public challengeParticipants;
    
    /**
     * Constructor for initializing the LMVToken contract with the provided NFT contract address.
     * Sets the ChallengeCounter to 0 and assigns the NFT contract instance to ChallengeNFT.
     * @param nftAddress The address of the NFT contract to be associated with the LMVToken for challenge NFT that will transfered to user as achivement.
     */
    constructor(address nftAddress) ERC20("Let's Move", "LMV") Ownable(msg.sender)EIP712("Let'sMove","1") {
            ChallengeCounter=0;
            ChallengeNFT = NFT(nftAddress); 
    }

    /**
     * Function to mint tokens to a specified address based on a claim amount.
     * 
     * @param claim The claim amount struct containing user, amount, and nonce.
     * @param _to The address to mint tokens to.
     */
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

    /**
     * Function to create a new challenge with the specified entry fee, token URI, and user address.
     * 
     * @param entryFee The entry fee required for the challenge.
     * @param tokenUri The URI of the token associated with the challenge.
     * @param user The address of the user creating the challenge.
     */
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

    /**
     * Function to allow a participant to enter a specific challenge identified by the challenge ID.
     * 
     * @param challengeId The ID of the challenge that the participant wants to enter.
     */
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

    /**
     * Function to conclude a challenge by transferring rewards to the winner and NFT ownership.
     * 
     * @param challengeId The ID of the challenge to be concluded.
     * @param claim The claim amount struct containing user, amount, and nonce for verification.
     */
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
    
    /**
     * @dev Returns the EIP712 domain hash for the LMVToken contract.
     * @return The EIP712 domain hash.
     */
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

    /**
     * @dev Verifies if the signature matches the provided claim amount by hashing the domain, claim struct, and recovering the signer.
     * @param claim The claim amount struct containing user, amount, nonce, v, r, and s.
     * @return bool indicating if the signature matches the owner's signature.
     */
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

    /**
     * @dev Generates a hash for a claim amount struct based on the provided parameters.
     * @param _owner The address of the owner for the claim.
     * @param _to The address to which the claim amount will be sent.
     * @param _amount The amount to be claimed.
     * @param _nonce The nonce value for the claim.
     * @return The keccak256 hash of the claim amount struct.
     */
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