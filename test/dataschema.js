const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
  

  describe("Data Schema Contract Test", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployDataSchema() {
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

      //Deploy Data Schema
      const DataSchemaContractFactory = await ethers.getContractFactory("DataSchemaContract", admin);
      const dataSchemaContract = await DataSchemaContractFactory.deploy(accountContract.address, productContract.address);

      return { accountContract, productContract, dataSchemaContract, admin, witness1, witness2, witness3, normalSigner1,normalSigner2 };
    }
  
    it("should create data schema and agree successfully", async function() {
      const { accountContract, productContract, dataSchemaContract, admin, witness1, witness2, witness3, normalSigner1,normalSigner2} = await loadFixture(deployDataSchema);
      //Create product
      const producthash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever111'));
      const productReceipt = await (await productContract.connect(normalSigner1).createProduct(producthash)).wait();
      const productEvent = productReceipt.events[0];
      const productId = productEvent.args.productId;
  
      await (await productContract.connect(witness1).approveProduct(productId, true)).wait();
      await (await productContract.connect(witness2).approveProduct(productId, true)).wait();
      //Create data schema
      const schemahash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever222'));
      
      const schemaReceipt = await (await dataSchemaContract.connect(normalSigner1).createDataSchema(schemahash, productId)).wait();
      const schemaEvent = schemaReceipt.events[0];
      const schemaId = schemaEvent.args.dataSchemaId;

      //Vote
      await (await dataSchemaContract.connect(witness1).approveDataSchema(schemaId, true)).wait();
      await (await dataSchemaContract.connect(witness2).approveDataSchema(schemaId, true)).wait();

      const votes = await dataSchemaContract.getVoteInfo(schemaId);
  
      expect(votes.agreeCount).to.be.equal(2);
      expect(votes.denyCount).to.be.equal(0);
      expect(votes.threshold).to.be.equal(2);
      expect(votes.witnessCount).to.be.equal(3);
  
      const schemaInfo = await dataSchemaContract.getDataSchema(schemaId);
      expect(schemaInfo.status).to.be.equal(1);
    });
    
    it("should create data schema and deny successfully", async function() {
      const { accountContract, productContract, dataSchemaContract, admin, witness1, witness2, witness3, normalSigner1,normalSigner2} = await loadFixture(deployDataSchema);
      //Create product
      const producthash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever111'));
      const productReceipt = await (await productContract.connect(normalSigner1).createProduct(producthash)).wait();
      const productEvent = productReceipt.events[0];
      const productId = productEvent.args.productId;
  
      await (await productContract.connect(witness1).approveProduct(productId, true)).wait();
      await (await productContract.connect(witness2).approveProduct(productId, true)).wait();
      //Create data schema
      const schemahash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever222'));
      
      const schemaReceipt = await (await dataSchemaContract.connect(normalSigner1).createDataSchema(schemahash, productId)).wait();
      const schemaEvent = schemaReceipt.events[0];
      const schemaId = schemaEvent.args.dataSchemaId;

      //Vote
      await (await dataSchemaContract.connect(witness1).approveDataSchema(schemaId, false)).wait();
      await (await dataSchemaContract.connect(witness2).approveDataSchema(schemaId, false)).wait();

      const votes = await dataSchemaContract.getVoteInfo(schemaId);
  
      expect(votes.agreeCount).to.be.equal(0);
      expect(votes.denyCount).to.be.equal(2);
      expect(votes.threshold).to.be.equal(2);
      expect(votes.witnessCount).to.be.equal(3);
  
      const schemaInfo = await dataSchemaContract.getDataSchema(schemaId);
      expect(schemaInfo.status).to.be.equal(2);
    });
  });
  