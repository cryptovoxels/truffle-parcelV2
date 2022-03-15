// import {expect,use,assert} from 'chai';
import { ParcelInstance } from '../types/truffle-contracts';
const Parcel = artifacts.require("Parcel")

const Zero  ='0x0000000000000000000000000000000000000000'

 contract("Parcel",async function (accounts) {

  const [wallet,walletTo,walletThree] = accounts
  let token:ParcelInstance
  beforeEach(async ()=>{
    token = await Parcel.deployed()
  })
  
  it('owner of contract is wallet', async () => {
    assert.equal(await token.owner(),wallet);
  });

  it('transferOwnership', async () => {
    await token.transferOwnership(walletTo)
    expect(await token.owner()).to.equal(walletTo);
  });

  it('owner takes back Ownership', async () => {
    await token.takeOwnership()
    expect(await token.owner()).to.equal(wallet);
  });

  it('Contract name is valid', async () => {
    expect(await token.symbol()).to.equal('CVPA');
    expect(await token.name()).to.equal('Voxels parcel');
  });
  
  it('Wallet has no parcels', async () => {
    expect((await token.parcelsOf(wallet)).length).to.be.equal(0)
  });
  
  it('Not contract owner mints a parcel - [should revert]', async () => {
    try{
      await token.mint(wallet,1,1,1,1,3,3,3,{from: walletTo})
      throw null
    }catch(e){
      assert.isNotNull(e)
    }
  });

  it('Bad parcel width - [should revert]', async () => {
    try{
      await token.mint(wallet,1,4,1,1,3,3,3)
      throw null
    }catch(e){
      assert.isNotNull(e)
    }

  });
  
  it('Mint a parcel -check balanceOf', async () => {

    await token.mint(wallet,1,1,1,1,3,3,3)

    expect((await token.balanceOf(wallet)).toNumber()).to.be.equal(1)
  });

  it('Mint and Check parcelsOf', async () => {
    const args = [wallet,2,3,3,3,4,4,4] as const
    await token.mint(...args)
    let q = await token.parcelsOf(wallet)
    expect(q.length).to.be.equal(2)
  });

  it('Contract Owner burns a parcel', async () => {
    await token.burn(2)

    let q = await token.balanceOf(wallet)
    expect(q.toNumber()).to.be.equal(1)
  });

  it('Get parcel bounding box', async () => {
    let boundingbox = await token.getBoundingBox(1)
    expect(Object.values(boundingbox).map((b)=>b.toNumber()).slice(0,6)).to.be.deep.equal([1,1,1,3,3,3])
  });
  
  
  it('Transfer a parcel', async () => {
    await token.transferFrom(wallet,walletTo,1)
    
    expect(await (await token.balanceOf(wallet)).toNumber()).to.be.equal(0)
    expect(await (await token.balanceOf(walletTo)).toNumber()).to.be.equal(1)
  });

  it('Transfer a parcel- operator not approved [should revert]', async () => {
  try{
      await token.transferFrom(walletTo,wallet,1,{from:walletThree})
      throw null
    }catch(e){
      assert.isNotNull(e)
    }
    
  });

  it('Transfer a parcel- approved', async () => {
    await token.approve(walletThree,1,{from:walletTo})

    await token.transferFrom(walletTo,wallet,1,{from:walletThree})

    expect(await (await token.balanceOf(wallet)).toNumber()).to.be.equal(1)
  });

  it('Change consumer - consumerOf', async () => {

    await token.changeConsumer(walletTo,1)

    let q = await token.consumerOf(1)
    expect(q).to.be.equal(walletTo)
  });

  it('Consumer cant transfer parcel', async () => {
    try{
      await token.transferFrom(wallet,walletTo,1,{from:walletTo})
      throw null
    }catch(e){
      assert.isNotNull(e)
    }

  });

  it('Transfer a parcel -new consumer is zero', async () => {

    await token.transferFrom(wallet,walletTo,1)

    let q = await token.consumerOf(1)
    expect(q).to.be.equal(Zero)
  });


});