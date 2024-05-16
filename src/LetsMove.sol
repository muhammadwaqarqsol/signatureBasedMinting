// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./NFT.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {rewardTypes} from "./libraries/rewardTypes.sol";

contract LMVToken is ERC20,EIP712,Ownable,ReentrancyGuard {
    using rewardTypes for rewardTypes.claimAmount;
    constructor() ERC20("Let's Move", "LMV") Ownable(msg.sender)EIP712("Let'sMove","1") {
    }

    enum Action{
        SignUp
    }

    /**
     * @notice Enable to mint new USDT tokens
     * @param to  to address you want to mint tokens
     * @param amount token amount you want to mint
     *
     * Can be mint by anyone to any address
     */
    function mint(address to, uint256 amount) public {
        _mint(to, amount * 10 ** 18);
    }

    function domainHash() internal view returns (bytes32) {
               // Encode the EIP-712 domain separator struct definition
        bytes32 hash = keccak256(
            abi.encode(
                // First, we encode the EIP-712 domain separator struct definition
                keccak256(
                    "EIP712Domain(string name,string version,address verifyingContract)"
                ),
                keccak256(bytes("Let'sMove")), // Name of the domain
                keccak256(bytes("1")), // Version of the domain
                address(this) // Address of the verifying contract
            )
        );
        // Return the resulting hash value
        return hash;
    }
    

    function generateHashforSignUp(
        address _owner,
        address _to,
        uint256 _amount,
        uint _nonce
    ) internal pure returns(bytes32){

    }

}