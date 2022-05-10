# Documentation concerning Parcels.sol

## Table of Content:
1. Contract behaviors
2. Basic methods and attributes
3. The contract methods


## 1 Contract behaviors

The contract replicates the behaviors of [the previous Cryptovoxels contract](https://etherscan.io/token/0x79986af15539de2db9a5086382daeda917a9cf0c).

Permissions:
- Only the contract owner (set by Ownable.sol) should be able to mint or burn an NFT (a parcel).
- Contract owner (set by ownable.sol) can transfer ownership to anyone.
- If contract creator has transferred ownership to a new owner, the contract creator shouldn't be able to mint / burn NFTs.
- The contract creator should always be able to take ownership of the contract if the current contract owner is not him/her.
- The contract owner should not be able to burn NFTs he/she does not own.

⚠️ This means the contract **owner can lose ownership of the contract** at any time with no accountability.

Functionalities:
- Users should be able to be given a parcel and transfer it just like any ERC721 NFT.
- Users should be able to approve other addresses to use their NFT just like any ERC721 NFT (setApprovalForAll(), approve())
- Parcels should have both an owner and a consumer (e.g. Owner and Renter)
- Anyone should be able to query the contract for parcel boundingBoxes or to obtain the list of parcels a wallet owns.

## 2 Basic methods and attributes
The contract is a simple ERC721 contract;

See [Open Zeppelin ERC721 Docs](https://docs.openzeppelin.com/contracts/2.x/api/token/erc721) for more information about ERC721.

The contract implements ERC721Enumerable;

See [Open Zeppelin ERC721Enumerable Docs](https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#IERC721Enumerable) for more information about ERC721Enumerable.

The contract implements ERC721Consumable;

See [EIP-4400 on Ethereum](https://eips.ethereum.org/EIPS/eip-4400) for more information about ERC721Consumable.

## 3 The contract methods

### takeOwnership
```js
    /**
     * @notice take ownership of the smart contract. Each parcels won't change owner.
     * @dev Only the creator can call this function. It lets the original contract creator take over the contract.
     * This allows the original contract creator to pass ownership to another worry-free that the other individual might rebel and never give ownership back
     */
    function takeOwnership() external {
        require(_msgSender()== creator);
        transferOwnership(creator);
    }
```
Note: This function is present in the old parcel contract and brought back.
At construction, the `address creator` variable is set as the original contract creator. Since the contract is `Ownable`, the owner of the contract can give ownership to someone else.
However, if the new owner is unwilling to cooperate with the creator, the original contract creator loses control over the contract.
This function is to guarantee the original contract creator can take back ownership of the contract with `takeOwnership()`.

This function does not affect NFT ownerships.

### transferOwnership override
```js
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
        if (_msgSender() == creator || _msgSender() == owner()) {
            _transferOwnership(newOwner);
        }
    }
```
Note: This function is present in the old parcel contract and brought back.
This override is necessary to make `takeOwnership` above work.

### getBoundingBox
```js
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
```
Note: This function is present in the old parcel contract and brought back.
Lets a caller obtain the bounding box of a parcel given a token_id

### parcelOf
```js
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
```
This is a new introduced function which lets the caller obtain a list of owned parcels given an address.