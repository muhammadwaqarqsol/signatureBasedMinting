// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract LMVTOKEN1 is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("usdt", "USDT")Ownable(msg.sender){
    } 

    uint256 _tokenId;
    mapping (address=>uint256) public creator_Challenge;
    mapping (uint256 => uint256) public pool_amount;
    mapping (uint256 => address) public winner_of_challenge;
    mapping (uint256 => uint256) public Entry_Fee;
    mapping (uint256=>mapping (address=>bool)) AlreadyEntered;
    mapping (uint256=>bool) public amountClaimed;

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount*10**18);
    }

    function createChallenge(address _creator,uint256 entryFee) public {
        _tokenId+=1;
        pool_amount[_tokenId]=0;
        creator_Challenge[_creator]=_tokenId;
        Entry_Fee[_tokenId]=entryFee;
    }


        function enterChallenge(uint256 challenge) public {
          require(balanceOf(msg.sender) >= Entry_Fee[challenge], "Insufficient balance to enter the challenge");
          require(AlreadyEntered[challenge][msg.sender] == false, "You have already entered this challenge");

          // Ensure the contract is approved to spend the entry fee tokens on behalf of the caller
          require(allowance(msg.sender, address(this)) >= Entry_Fee[challenge], "Insufficient allowance to transfer tokens");

          // Transfer Entry Fee tokens from the caller to the contract
          transferFrom(msg.sender, address(this), Entry_Fee[challenge]);

          // Update the pool amount for the challenge
          pool_amount[challenge] += Entry_Fee[challenge];

          // Mark the user as entered
          AlreadyEntered[challenge][msg.sender] = true;
      }


    function setWinner(uint256 challenge,address winner)public onlyOwner{
        require(winner_of_challenge[challenge]==address(0),"Already Annouced Winner");
        winner_of_challenge[challenge]=winner;
    }
     

    function claimChallengeReward(uint256 challengeId)public {
        require(winner_of_challenge[challengeId]==msg.sender,"you are not the winner");
        require(amountClaimed[challengeId],"Amount AlreadyClaimed");
        amountClaimed[challengeId]=true;
        uint256 amount=pool_amount[challengeId];
        pool_amount[challengeId]=0;
        transferFrom(address(this), msg.sender,amount);
    }

}