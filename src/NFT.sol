// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFT is ERC721, ERC721URIStorage {
    uint256 public _tokenId; // Tracking the no of tokens minted

    constructor() ERC721("LetsMove", "LMV") {}

    /**
     * @notice Enables users to create NFT Token
     * @param _tokenURI  NFT detail of ipfs url
     * @param _to  To transfer address 
     *
     * user create the NFT.
     * Function should be perform by user to create token.
     */
    function createToken(string memory _tokenURI, address _to) public returns (uint256) {
        require(msg.sender != address(0), "Has Zero Address");
        require(bytes(_tokenURI).length > 0, "Empty URI");
        _tokenId += 1; // Increment the tokenIds counter
        uint256 newTokenId=_tokenId;      
        _mint(_to, newTokenId); // mint the token to the address
        _setTokenURI(newTokenId, _tokenURI); // set the tokenURI to the tokenId.
        return newTokenId;
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
