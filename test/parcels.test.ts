// import {expect,use,assert} from 'chai';
import { ParcelInstance } from '../types/truffle-contracts';
const Parcel = artifacts.require("Parcel")
const {
  constants,    // Common constants, like the zero address and largest integers
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  time,         // Time manipulation
} = require('@openzeppelin/test-helpers');


contract("Parcel - Unit test",async function (accounts) {

  const [wallet,walletTo,walletThree] = accounts
  let token:ParcelInstance
  beforeEach(async ()=>{
    token = await Parcel.new()
  })
  
  it('owner of contract is wallet', async () => {
    assert.equal(await token.owner(),wallet);
  });

  
  it('Contract name is valid', async () => {
    expect(await token.symbol()).to.equal('CVPA');
    expect(await token.name()).to.equal('Voxels parcel');
  });

  it('Contract support ERC721 interface', async () => {
    expect(await token.supportsInterface('0x80ac58cd')).to.be.true
  });

  it('Contract does not support ERC1155 interface', async () => {
    expect(await token.supportsInterface('0xd9b67a26')).to.be.false
  });

  it('Owner calls transferOwnership', async () => {
    try{
      await token.transferOwnership(walletTo)
      throw null
    }catch(e){
      assert.isNull(e)
    }
  });

  it('Non-owner calls transferOwnership - Should revert', async () => {
    await expectRevert(token.transferOwnership(walletTo,{from:walletTo}),'Ownable: invalid permission')
  });

  it('call ParcelsOf()', async () => {
    let result = await token.parcelsOf(wallet,0)

    expect(result[0].length).to.be.equal(0)
    expect(result[1].toNumber()).to.be.equal(0)
  });

  it('call balanceOf()', async () => {
    expect((await token.balanceOf(wallet)).toNumber()).to.be.equal(0)
  });

  it('Owner calls mint', async () => {
    try{
      await token.mint(wallet,1,1,1,1,3,3,3)
      throw null
    }catch(e){
      assert.isNull(e)
    }
  });

  it('Bad parcel width - [should revert]', async () => {
      await expectRevert(token.mint(wallet,1,4,1,1,3,3,3),'Width is unsupported')
  });

  it('Mint parcel to Zero - [should revert]', async () => {

    await expectRevert(token.mint(constants.ZERO_ADDRESS,1,1,1,1,3,3,3),"Can't mint to address Zero")
  });

    
  it('Not contract owner mints a parcel - [should revert]', async () => {

      await expectRevert(token.mint(wallet,1,1,1,1,3,3,3,{from: walletTo}),"Ownable: caller is not the owner")

  });
})


contract("Parcels - Integration tests",async function (accounts) {

  const [wallet,walletTo,walletThree] = accounts
  let token:ParcelInstance
  beforeEach(async ()=>{
    token = await Parcel.deployed()
  })

  it('transferOwnership', async () => {
    await token.transferOwnership(walletTo)
    expect(await token.owner()).to.equal(walletTo);
  });

  it('owner takes back Ownership', async () => {
    await token.takeOwnership()
    expect(await token.owner()).to.equal(wallet);
  });

   // We mint a parcel, expect balance to be 1
  it('Mint a parcel + check balanceOf', async () => {

    await token.mint(wallet,1,1,1,1,3,3,3)

    expect((await token.balanceOf(wallet)).toNumber()).to.be.equal(1)
  });

   // We mint another parcel, expect length of parcelsOf to be = 2
  it('Mint a parcel + Check parcelsOf', async () => {
    const args = [wallet,2,3,3,3,4,4,4] as const
    await token.mint(...args)
    let q = await token.parcelsOf(wallet,0)
    expect(q[0].length).to.be.equal(2)
    // make sure page is 0
    expect(q[1].toNumber()).to.be.equal(0)
  });

  // We burn a parcel, expect balanceOf to return 1
  it('Contract Owner burns a parcel', async () => {
    await token.burn(2)

    let q = await token.balanceOf(wallet)
    expect(q.toNumber()).to.be.equal(1)
  });

  it('Get parcel bounding box', async () => {
    let boundingbox = await token.getBoundingBox(1)
    expect(Object.values(boundingbox).map((b)=>b.toNumber()).slice(0,6)).to.be.deep.equal([1,1,1,3,3,3])
  });
  
  // Transfer parcel from wallet (balance of 1) to WalletTo (balance of 0); expect new balance to be 0 and 1 respectively
  it('Transfer a parcel', async () => {
    await token.transferFrom(wallet,walletTo,1)
    
    expect(await (await token.balanceOf(wallet)).toNumber()).to.be.equal(0)
    expect(await (await token.balanceOf(walletTo)).toNumber()).to.be.equal(1)
  });

  it('Transfer a parcel- operator not approved [should revert]', async () => {
      await expectRevert(token.transferFrom(walletTo,wallet,1,{from:walletThree}),'ERC721: transfer caller is not owner nor approved')
  });

  it('Transfer a parcel- approved', async () => {
    await token.approve(walletThree,1,{from:walletTo})

    await token.transferFrom(walletTo,wallet,1,{from:walletThree})

    expect((await token.balanceOf(wallet)).toNumber()).to.be.equal(1)
  });

  it('Change consumer - consumerOf', async () => {

    await token.changeConsumer(walletTo,1)

    let q = await token.consumerOf(1)
    expect(q).to.be.equal(walletTo)
  });

  // Consumer walletTo tries to transfer parcel from wallet to himself.
  it('Consumer cant transfer parcel', async () => {
      await expectRevert.unspecified(token.transferFrom(wallet,walletTo,1,{from:walletTo}))
  });

  it('Transfer a parcel -new consumer is zero', async () => {

    await token.transferFrom(wallet,walletTo,1)

    let q = await token.consumerOf(1)
    expect(q).to.be.equal(constants.ZERO_ADDRESS)
  });

  // This test can take about 11 seconds
  it('Mass mint 150 parcels', async () => {

    for(let i = 2; i<=152;i++){
      await token.mint(walletTo,i,3,3,3,4,4,4)
    }

    expect((await token.balanceOf(walletTo)).toNumber()).to.be.equal(152)
  });
  
  it('parcelsOf - Check pagination', async () => {
    // We know for a fact that user walletTo has 152 NFTs
    let tuple = await token.parcelsOf(walletTo,0)
    let tuple2 = await token.parcelsOf(walletTo,1)
    // Max num of items / page is 150
    expect(tuple[0].length).to.be.equal(150)
    // Check we have been given a new page index
    expect(tuple[1].toNumber()).to.be.equal(1)

    // in page index 1 there should be only 2 NFTs left
    expect(tuple2[0].length).to.be.equal(2)
    // We reached the max, the next page should be non-existant
    expect(tuple2[1].toNumber()).to.be.equal(0)
  });

  // Can take 30 seconds
  it('Mass mint another 148 parcels', async () => {

    for(let i = 153; i<=300;i++){
      // Mass minting like this will 99% never happen in real life. However it has the ability to "crash" the local environment.
      // We therefore wait 100ms between each mints to slow things down.
      await (()=>new Promise((resolve,reject)=>setTimeout(()=>{resolve(true)},100)))()
      await token.mint(walletTo,i,3,3,3,4,4,4)
    }

    expect((await token.balanceOf(walletTo)).toNumber()).to.be.equal(300)
  });

  it('parcelsOf - Check pagination for 300 parcels', async () => {
    // We know for a fact that user walletTo has 300 NFTs
    let tuple = await token.parcelsOf(walletTo,0)
    let tuple2 = await token.parcelsOf(walletTo,1)

    // Max num of items / page is 150
    expect(tuple[0].length).to.be.equal(150)
    // Check we have been given a new page index
    expect(tuple[1].toNumber()).to.be.equal(1)

    // in page index 1 there should be only 150 NFTs
    expect(tuple2[0].length).to.be.equal(150)
    // We reached the max, the next page should be non-existant
    expect(tuple2[1].toNumber()).to.be.equal(0)

  });
});
