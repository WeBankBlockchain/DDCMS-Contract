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
    const [admin, witness1, witness2, normalSigner1, normalSigner2 ] = await ethers.getSigners();
    const AccountContractFactory = await ethers.getContractFactory("AccountContract", admin);
    const accountContract = await AccountContractFactory.deploy();
    
    const adminAcnt = await accountContract.getAccountByAddress(admin.address);

    expect(adminAcnt.accountType).to.be.equal(3);
    expect(adminAcnt.accountStatus).to.be.equal(1);

    const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever'));
    await accountContract.connect(admin).setupAccounts([witness1.address, witness2.address], [2, 2], [hash, hash]);

    await accountContract.connect(admin).setupAccounts([normalSigner1.address, normalSigner2.address], [1, 1], [hash, hash]);


    const ProductContractFactory = await ethers.getContractFactory("ProductContract", admin);
    const productContract = await ProductContractFactory.deploy(accountContract.address);
    return { accountContract, productContract, admin, witness1, witness2,normalSigner1,normalSigner2 };
  }

  it("should create product and agree successfully", async function() {
    const {accountContract, productContract, admin, witness1, witness2,normalSigner1,normalSigner2 } = await loadFixture(deployProduct);
    const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever'));
    const receipt = await (await productContract.connect(normalSigner1).createProduct(hash)).wait();
    const event = receipt.events[0];
    const productId = event.args.productId;

    await (await productContract.connect(witness1).approveProduct(productId, true)).wait();


    const votes = await productContract.getVoteInfo(productId);

    expect(votes.agreeCount).to.be.equal(1);
    expect(votes.denyCount).to.be.equal(0);
    expect(votes.threshold).to.be.equal(1);


    const productInfo = await productContract.getProduct(productId);
    expect(productInfo.status).to.be.equal(1);
    
  });
  
  it("should create product and deny successfully", async function() {
    const {accountContract, productContract, admin, witness1, witness2,normalSigner1,normalSigner2 } = await loadFixture(deployProduct);
    const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever'));
    const receipt = await (await productContract.connect(normalSigner1).createProduct(hash)).wait();
    const event = receipt.events[0];
    const productId = event.args.productId;

    await (await productContract.connect(witness1).approveProduct(productId, false)).wait();


    const votes = await productContract.getVoteInfo(productId);

    expect(votes.agreeCount).to.be.equal(0);
    expect(votes.denyCount).to.be.equal(1);
    expect(votes.threshold).to.be.equal(1);


    const productInfo = await productContract.getProduct(productId);
    expect(productInfo.status).to.be.equal(2);
    
  });
});
