//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ERC-721 Consumer Role extension
///  Note: the ERC-165 identifier for this interface is 0x953c8dfa
/* is ERC721 */
interface IERC721Consumable {
    /// @notice Emitted when `owner` changes the `consumer` of an NFT
    /// The zero address for consumer indicates that there is no consumer address
    /// When a Transfer event emits, this also indicates that the consumer address
    /// for that NFT (if any) is set to none
    event ConsumerChanged(
        address indexed owner,
        address indexed consumer,
        uint256 indexed tokenId
    );

    /// @notice Get the consumer address of an NFT
    /// @dev The zero address indicates that there is no consumer
    /// Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to get the consumer address for
    /// @return The consumer address for this NFT, or the zero address if there is none
    function consumerOf(uint256 _tokenId) external view returns (address);

    /// @notice Change or reaffirm the consumer address for an NFT
    /// @dev The zero address indicates there is no consumer address
    /// Throws unless `msg.sender` is the current NFT owner, an authorised
    /// operator of the current owner or approved address
    /// Throws if `_tokenId` is not valid NFT
    /// @param _consumer The new consumer of the NFT
    function changeConsumer(address _consumer, uint256 _tokenId) external;
}

contract Parcel is IERC721Consumable, ERC721Enumerable, Ownable {
    ///@dev ultimate creator of the contract
    address immutable creator;
    /// @dev Mapping from token ID to consumer address
    mapping(uint256 => address) internal _tokenConsumers;

    /// @dev Parcel id to bounding boxes
    mapping(uint256 => BoundingBox) internal boundingBoxes;

    /// @dev The structure of a parcel bounding box
    struct BoundingBox {
        int16 x1;
        int16 y1;
        int16 z1;
        int16 x2;
        int16 y2;
        int16 z2;
    }

    /// @dev  Represents the base of the tokenUri
    string private _baseUri;

    constructor() ERC721("Voxels parcel", "CVPA") {
        _baseUri = "https://www.cryptovoxels.com/p/";
        creator = msg.sender;
    }

    /**
    * @notice Requires positive width,height and depth
    * @dev Creates a new parcel as NFT.
    * @param _to address receiving the Parcel
    * @param _tokenId the id of the new Parcel.
    * @param x1 property x1 of the first point of the bounding box
    * @param y1 property y1 of the first point of the bounding box
    * @param z1 property z1 of the first point of the bounding box
    * @param x2 property x1 of the second point of the bounding box
    * @param y2 property x1 of the second point of the bounding box
    * @param z2 property x1 of the second point of the bounding box
    */
    function mint(
        address _to,
        uint256 _tokenId,
        int16 x1,
        int16 y1,
        int16 z1,
        int16 x2,
        int16 y2,
        int16 z2
    ) external onlyOwner {
        require(_to != address(0), "Can't mint to address Zero");
        require(x2 > x1, "Width is unsupported");
        require(y2 > y1, "height is unsupported");
        require(z2 > z1, "Depth is unsupported");

        // Set bounds
        boundingBoxes[_tokenId] = BoundingBox(x1, y1, z1, x2, y2, z2);

        _safeMint(_to, _tokenId);
    }
        
    /**
    * @notice Sets the baseURI for tokens
    * @dev Sets the baseURI for tokens, only the contract owner can call;
    * @param baseUri a string that forms a URI
    */
    function setBaseURI(string memory baseUri) external onlyOwner {
        _baseUri = baseUri;
    }

    /**
     * @notice Base URI for computing {tokenURI}
     * @dev overrides ERC721 - _baseURI
     * @return _baseUri Baseuri of metadata
     */
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _baseUri;
    }

    /**
     * @notice Burn a parcel if caller is contract owner and parcel is owned by caller.
     * @dev Only the contract owner can call; We purposely only allow the contract owner to burn. NFT owners cannot destroy land.
     * @dev see @ERC721._burn();
     * @param _tokenId a token Id
     */
    function burn(uint256 _tokenId) public onlyOwner {
        require(
            ownerOf(_tokenId) == owner(),
            "Token owner is not contract owner"
        );
        _burn(_tokenId);

        // Delete bounding box metadata
        delete boundingBoxes[_tokenId];
    }

    /**
     * @dev See {IERC721Consumable-consumerOf}
     */
    function consumerOf(uint256 _tokenId)
        external
        view
        override
        returns (address)
    {
        require(
            _exists(_tokenId),
            "ERC721Consumable: consumer query for nonexistent token"
        );
        return _tokenConsumers[_tokenId];
    }

    /**
     * @dev See {IERC721Consumable-changeConsumer}
     */
    function changeConsumer(address _consumer, uint256 _tokenId)
        external
        override
    {
        address tokenOwner = this.ownerOf(_tokenId);
        require(
            _msgSender() == tokenOwner ||
                _msgSender() == getApproved(_tokenId) ||
                isApprovedForAll(tokenOwner, _msgSender()),
            "ERC721Consumable: changeConsumer caller is not owner nor approved"
        );
        _changeConsumer(tokenOwner, _consumer, _tokenId);
    }

    /**
     * @dev Changes the consumer
     * Requirement: `tokenId` must exist
     */
    function _changeConsumer(
        address tokenOwner,
        address _consumer,
        uint256 _tokenId
    ) internal {
        _tokenConsumers[_tokenId] = _consumer;
        emit ConsumerChanged(tokenOwner, _consumer, _tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Consumable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721Consumable}.
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);

        _changeConsumer(_from, address(0), _tokenId);
    }
    
    /**
     * @notice Take ownership of the smart contract. Each parcels won't change owner.
     * @dev Only the creator can call this function. It lets the original contract creator take over the contract.
     * This allows the original contract creator to pass ownership to another worry-free that the other individual might rebel and never give ownership back
     * This means the current owner can lose ownership at anytime without accountability.
     */
    function takeOwnership() external {
        require(_msgSender() == creator);
        transferOwnership(creator);
    }

    /**
     * Overrides transferOwnership of Ownable.
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner or the contract creator.
     */
    function transferOwnership(address newOwner) public override(Ownable) {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        require(_msgSender() == creator || _msgSender() == owner(),'Ownable: invalid permission');

         _transferOwnership(newOwner);
    }

    /**
     * @notice Returns bounding box of the parcel
     * @param _tokenId token Id of the parcel
     * @return x1 number, y1 number, z1 number,x2 number,y2 number,z2 number
     */
    function getBoundingBox(uint256 _tokenId)
        external
        view
        returns (
            int16 x1,
            int16 y1,
            int16 z1,
            int16 x2,
            int16 y2,
            int16 z2
        )
    {
        require(_exists(_tokenId), "Token id does not exists");

        x1 = boundingBoxes[_tokenId].x1;
        y1 = boundingBoxes[_tokenId].y1;
        z1 = boundingBoxes[_tokenId].z1;
        x2 = boundingBoxes[_tokenId].x2;
        y2 = boundingBoxes[_tokenId].y2;
        z2 = boundingBoxes[_tokenId].z2;
    }

    /**
     * @notice Returns the parcels owned by _owner
     * @param tokenOwner Address of the owner
     * @return _ids list of token ids
     */
    function parcelsOf(address tokenOwner)
        external
        view
        returns (uint256[] memory _ids)
    {
        require(tokenOwner != address(0), "Address Zero not supported");
        uint256 balance;
        balance = balanceOf(tokenOwner);
        uint256[] memory ids = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            ids[i] = tokenOfOwnerByIndex(tokenOwner, i);
        }
        return ids;
    }
}