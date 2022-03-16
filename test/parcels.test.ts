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
  
  it('Owner calls transferOwnership', async () => {
    try{
      await token.transferOwnership(walletTo)
      throw null
    }catch(e){
      assert.isNull(e)
    }
  });

  it('call ParcelsOf()', async () => {
    expect((await token.parcelsOf(wallet)).length).to.be.equal(0)
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
    let q = await token.parcelsOf(wallet)
    expect(q.length).to.be.equal(2)
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


});