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
    const [normalSigner, governor ] = await ethers.getSigners();
    const AccountModuleFactory = await ethers.getContractFactory("AccountModule");
    const accountModule = await AccountModuleFactory.deploy(governor.address);
    

    return { accountModule, normalSigner, governor };
  }

  it("Should register and query successful", async function () {
    const { accountModule, normalSigner, governor} = await loadFixture(deployAccount);
    const accountType = 1;
    const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever'));
    const receipt = await (await (accountModule.connect(normalSigner).register(accountType,  hash))).wait();
    const event = receipt.events[0];
    expect(event.args.did).to.be.equal('0x0001208c00db55262550c247e6381d970186c88ffce887de6be980d4f0aa81de');
    expect(event.args.accountType).to.be.equal(accountType);
    expect(event.args.addr).to.be.equal(normalSigner.address);
    expect(event.args.hash).to.be.equal(hash);

    var accountData = await accountModule.getAccountByAddress(normalSigner.address);

    expect(accountData.did).to.be.equal('0x0001208c00db55262550c247e6381d970186c88ffce887de6be980d4f0aa81de');
    expect(accountData.addr).to.be.equal(normalSigner.address);
    expect(accountData.accountType).to.be.equal(accountType);
    expect(accountData.status).to.be.equal(1);
    expect(event.args.hash).to.be.equal(hash);

    accountData = await accountModule.getAccountByDid(accountData.did);

    expect(accountData.did).to.be.equal('0x0001208c00db55262550c247e6381d970186c88ffce887de6be980d4f0aa81de');
    expect(accountData.addr).to.be.equal(normalSigner.address);
    expect(accountData.accountType).to.be.equal(accountType);
    expect(accountData.status).to.be.equal(1);
    expect(event.args.hash).to.be.equal(hash);

  });
});
