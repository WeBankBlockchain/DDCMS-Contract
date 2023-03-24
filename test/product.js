const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("Product Contract Test", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployProduct() {
    //Prepare accounts
    const [admin, witness1, witness2, witness3, normalSigner1, normalSigner2 ] = await ethers.getSigners();
    //Deploy account contract
    const AccountContractFactory = await ethers.getContractFactory("AccountContract", admin);
    const accountContract = await AccountContractFactory.deploy();
    //Register 3 witness accounts and 2 normal accounts
    const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever'));
    await (await accountContract.connect(witness1).register(2, hash)).wait();
    await (await accountContract.connect(witness2).register(2, hash)).wait();
    await (await accountContract.connect(witness3).register(2, hash)).wait();
    await (await accountContract.connect(normalSigner1).register(1, hash)).wait();
    await (await accountContract.connect(normalSigner2).register(1, hash)).wait();

    const witness1Acnt = await accountContract.getAccountByAddress(witness1.address);
    const witness2Acnt = await accountContract.getAccountByAddress(witness2.address);
    const witness3Acnt = await accountContract.getAccountByAddress(witness3.address);
    const normal1Acnt = await accountContract.getAccountByAddress(normalSigner1.address);
    const normal2Acnt = await accountContract.getAccountByAddress(normalSigner2.address);
    await accountContract.connect(admin).approve(witness1Acnt.did, true);
    await accountContract.connect(admin).approve(witness2Acnt.did, true);
    await accountContract.connect(admin).approve(witness3Acnt.did, true);
    await accountContract.connect(admin).approve(normal1Acnt.did, true);
    await accountContract.connect(admin).approve(normal2Acnt.did, true);

    //Deploy Product
    const ProductContractFactory = await ethers.getContractFactory("ProductContract", admin);
    const productContract = await ProductContractFactory.deploy(accountContract.address);
    return { accountContract, productContract, admin, witness1, witness2, witness3, normalSigner1,normalSigner2 };
  }

  it("should create product and agree successfully", async function() {
    const { accountContract, productContract, admin, witness1, witness2, witness3, normalSigner1,normalSigner2} = await loadFixture(deployProduct);
    const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever111'));
    const receipt = await (await productContract.connect(normalSigner1).createProduct(hash)).wait();
    const event = receipt.events[0];
    const productId = event.args.productId;

    await (await productContract.connect(witness1).approveProduct(productId, true)).wait();
    await (await productContract.connect(witness2).approveProduct(productId, true)).wait();

    const votes = await productContract.getVoteInfo(productId);

    expect(votes.agreeCount).to.be.equal(2);
    expect(votes.denyCount).to.be.equal(0);
    expect(votes.threshold).to.be.equal(2);
    expect(votes.witnessCount).to.be.equal(3);

    const productInfo = await productContract.getProduct(productId);
    expect(productInfo.status).to.be.equal(1);
  });
  
  it("should create product and deny successfully", async function() {
    const { accountContract, productContract, admin, witness1, witness2, witness3, normalSigner1,normalSigner2} = await loadFixture(deployProduct);
    const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever111'));
    const receipt = await (await productContract.connect(normalSigner1).createProduct(hash)).wait();
    const event = receipt.events[0];
    const productId = event.args.productId;

    await (await productContract.connect(witness1).approveProduct(productId, false)).wait();
    await (await productContract.connect(witness2).approveProduct(productId, false)).wait();

    const votes = await productContract.getVoteInfo(productId);

    expect(votes.agreeCount).to.be.equal(0);
    expect(votes.denyCount).to.be.equal(2);
    expect(votes.threshold).to.be.equal(2);
    expect(votes.witnessCount).to.be.equal(3);

    const productInfo = await productContract.getProduct(productId);
    expect(productInfo.status).to.be.equal(2);
  });
});
