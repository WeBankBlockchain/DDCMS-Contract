const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("Account Contract Test", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployAccount() {
    const [admin, witness1, witness2, normalSigner1, normalSigner2 ] = await ethers.getSigners();
    const AccountContractFactory = await ethers.getContractFactory("AccountContract", admin);
    const accountContract = await AccountContractFactory.deploy();
    
    const adminAcnt = await accountContract.getAccountByAddress(admin.address);

    expect(adminAcnt.accountType).to.be.equal(3);
    expect(adminAcnt.accountStatus).to.be.equal(1);


    return { accountContract, admin, witness1, witness2,normalSigner1,normalSigner2 };
  }

  it("Should setup witness", async function () {
    const { accountContract, admin, witness1, witness2} = await loadFixture(deployAccount);
    const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever'));
    await accountContract.connect(admin).setupAccounts([witness1.address, witness2.address], [2, 2], [hash, hash]);

    const witness1Acnt = await accountContract.getAccountByAddress(witness1.address);
    expect(witness1Acnt.accountType).to.be.equal(2);
    expect(witness1Acnt.accountStatus).to.be.equal(1);

  });

  it("Should register and approve success", async function () {
    const { accountContract, admin, witness1, witness2,normalSigner1,normalSigner2} = await loadFixture(deployAccount);
    //Register and approve
    const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever'));
    const receipt = await (await accountContract.connect(normalSigner1).register(hash)).wait();
    var normalSigner1Acnt = await accountContract.getAccountByAddress(normalSigner1.address);
    expect(normalSigner1Acnt.accountType).to.be.equal(1);
    expect(normalSigner1Acnt.accountStatus).to.be.equal(0);
    
    await (await accountContract.connect(admin).approve(normalSigner1Acnt.did, true)).wait();
    
    normalSigner1Acnt = await accountContract.getAccountByAddress(normalSigner1.address);
    expect(normalSigner1Acnt.accountType).to.be.equal(1);
    expect(normalSigner1Acnt.accountStatus).to.be.equal(1);

    //Register and deny
    await (await accountContract.connect(normalSigner2).register(hash)).wait();
    var normalSigner2Acnt = await accountContract.getAccountByAddress(normalSigner2.address);
    expect(normalSigner2Acnt.accountType).to.be.equal(1);
    expect(normalSigner2Acnt.accountStatus).to.be.equal(0);
    
    await (await accountContract.connect(admin).approve(normalSigner2Acnt.did, false)).wait();
    
    normalSigner2Acnt = await accountContract.getAccountByAddress(normalSigner2.address);
    expect(normalSigner2Acnt.accountType).to.be.equal(1);
    expect(normalSigner2Acnt.accountStatus).to.be.equal(2);

  });
});
