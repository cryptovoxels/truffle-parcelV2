//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC721Consumable.sol";

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
    * @dev Creates a new parcel as NFT. Only the owner of the contract can call.
    * @dev NFTs are allowed to overlap each other by design.
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
     * @dev 
     * @notice Function that returns the parcels owned by _owner (pages of 150 elements)
     * @param tokenOwner Address of the owner
     * @param page page index, 0 is the first 150 elements of the balance.
     * @return _ids list of token ids and _nextpage is the index of the next page, _nextpage is 0 if there is no more pages.
     */
    function parcelsOf(address tokenOwner,uint256 page)
        external
        view
        returns (uint256[] memory _ids,uint256 _nextpage)
    {
        require(tokenOwner != address(0), "Address Zero not supported");
        require(page >= 0, "Page index has to be zero or more.");
        uint256 max = 150;
        uint256 balance;
        balance = balanceOf(tokenOwner);
        uint256 offset = page*max;
        uint256 resultSize = balance;
        if(balance>= max+offset){
            // balance is above or equal to 150* page index + 150
            resultSize = max;
        }else if (balance< max+offset){
            // balance is less than 150* page index + 150
            resultSize = balance - offset;
        }
        uint256[] memory ids = new uint256[](resultSize);
        uint256 index = 0;
        for (uint256 i = offset; i < resultSize+offset; i++) {
            ids[index] = tokenOfOwnerByIndex(tokenOwner, i);
            index++;
        }
        if(balance<=(ids.length+offset)){
            return (ids,0);
        }else{
            return (ids,page+1);
        }
        
    }
}