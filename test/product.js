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
    const [normalSigner, governor ] = await ethers.getSigners();
    const AccountModuleFactory = await ethers.getContractFactory("AccountModule");
    const accountModule = await AccountModuleFactory.deploy(governor.address);
    
    //register and approve the normal signer
    const accountType = 1;
    const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever'));
    const receipt = await (await (accountModule.connect(normalSigner).register(accountType,  hash))).wait();
    const did = receipt.events[0].args.did;

    await (await (accountModule.connect(governor).approve(ethers.utils.arrayify(did), true))).wait();
    
    const ProductModuleFactory = await ethers.getContractFactory("ProductModule");
    const productModule = await ProductModuleFactory.deploy(governor.address, accountModule.address);
    
    return {productModule, normalSigner, governor };
  }

  it("should create product successfully", async function() {
    const {productModule, normalSigner, governor} = await loadFixture(deployProduct);
    const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever'));
    const receipt = await (await productModule.connect(normalSigner).createProduct(hash)).wait();
    const event = receipt.events[0];

    const hash2 = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever2'));
    const receipt2 = await (await productModule.connect(normalSigner).createProduct(hash2)).wait();
    const event2 = receipt2.events[0];
    
  });
  
  it("should approve product successfully", async function() {
    const {productModule, normalSigner, governor} = await loadFixture(deployProduct);
    const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever'));
    const receipt = await (await productModule.connect(normalSigner).createProduct(hash)).wait();
    const event = receipt.events[0];
    
    const productId = event.args.productId;
    // console.log(productId);

    const approveReceipt = await (await productModule.connect(governor).approveProduct(productId, true)).wait();
    expect(approveReceipt.events[0].event).to.be.equal("ProductApproved");
    
  });

  it("should deny product successfully", async function() {
    const {productModule, normalSigner, governor} = await loadFixture(deployProduct);
    const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever'));
    const receipt = await (await productModule.connect(normalSigner).createProduct(hash)).wait();
    const event = receipt.events[0];
    
    const productId = event.args.productId;
    // console.log(productId);

    const approveReceipt = await (await productModule.connect(governor).approveProduct(productId, false)).wait();
    expect(approveReceipt.events[0].event).to.be.equal("ProductDenied");
    
  });
});
