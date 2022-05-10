# Documentation concerning Parcels.sol

## Table of Content:
1. Contract behaviors
2. Basic methods and attributes
3. The contract methods


## 1 Contract behaviors

The contract replicates the behaviors of [the previous Cryptovoxels contract](https://etherscan.io/token/0x79986af15539de2db9a5086382daeda917a9cf0c).

- Only the contract owner should be able to mint or burn a parcel.
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
     * @dev takeOwnership() let the original contract creator to take over the contract.
     */
    function takeOwnership() external {
        require(_msgSender()== creator);
        transferOwnership(creator);
    }
```
Note: This function is present in the old parcel contract and brought back.
At construction, the `address creator` variable is set as the original contract creator. Since the contract is `Ownable`, the owner of the contract can give ownership to someone else.
However, if new owner is unwilling to cooperate, the original contract creator can take back ownership of the contract with `takeOwnership()`.

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
     * @dev 
     * @notice Function that returns the parcels owned by _owner (pages of 150 elements)
     * @param tokenOwner Address of the owner
     * @param page page index, 0 is the first 150 elements of the balance if balance >= 150.
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
```
This is a new introduced function which lets the caller obtain a list of owned parcels given an address.
The caller has to give an index as a second argument. This index will serve as "page number". There are 150 items per pages.
If a user has 200 NFTs, it will take two calls; `parcelsOf('0x...',0)` and `parcelsOf('0x...',1)`, both of which will return an array 
of token ids and the index of the next page.
If there is no next page, the index 0 is returned.
Using our previous example, `parcelsOf('0x...',0)` returns `1: [5,6,7...](150) 2: 1` and `parcelsOf('0x...',1)` returns `1: [155,156,157...](50) 2: 0`