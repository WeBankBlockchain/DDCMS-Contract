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
      
      const DataSchemaModuleFactory = await ethers.getContractFactory("DataSchemaModule");
      const dataSchemaModule = await DataSchemaModuleFactory.deploy(governor.address, accountModule.address);
      
      return {dataSchemaModule, normalSigner, governor };
    }
  
    it("should create data schema successfully", async function() {
      const {dataSchemaModule, normalSigner, governor} = await loadFixture(deployProduct);
      const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever'));
      const receipt = await (await dataSchemaModule.connect(normalSigner).createDataSchema(hash)).wait();
      const event = receipt.events[0];

      const hash2 = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('whatever2'));
      const receipt2 = await (await dataSchemaModule.connect(normalSigner).createDataSchema(hash2)).wait();
      const event2 = receipt2.events[0];
      
    });

    
  });
  