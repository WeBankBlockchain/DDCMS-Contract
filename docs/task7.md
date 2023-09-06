# Task7 添加数据上链的多样性

> 作者：李奇龙
>
> 学校：广东工业大学

## 一、添加内容

`DataSchemaContract`合约中添加内容如下：

* 结构体：`DataDetail`
* 事件：`event CreateDataDetailEvent(bytes32 indexed dataSchemaId,string dataSchemaName,string contentJson);`
* 函数：
  * `createDataDetail(bytes32,bytes32,bytes32,string,string,string)`
  * `getDataDetail(bytes32) returns(DataDetail)`
  * `_createDataDetail(bytes32,string,string)`

## 二、内容说明

1. `DataDetail`实现如下

   ```solidity
   struct DataDetail {
       string dataSchemaName;
       string contentJson;
   }
   // 对应mapping
   // dataSchemaId映射到DataDetail
   mapping(bytes32 => DataDetail) dataDetails;
   ```

2. 添加事件说明

   `CreateDataDetailEvent()`：当调用`_createDataDetail`函数时响应事件，说明创建数据细节成功

3. 添加函数说明

   * `createDataDetail()`函数具体实现如下：

     该函数用于判断添加data数据前的合法性，判断通过后调用`_createDataDetail()`函数保存数据

     ```solidity
     function createDataDetail(
         bytes32 _hash,
         bytes32 productBid,
         bytes32 dataSchemaId,
         string memory productId,
         string memory _contentJson,
         string memory dataSchemaName
     ) external {
         //Get owner info
         AccountContract.AccountData memory ownerAccount = accountContract
         	.getAccountByAddress(msg.sender);
         //Get product info
         ProductContract.ProductInfo memory productInfo = productContract
         	.getProduct(productBid);
         //Validate product and owner
         require(
         	productInfo.status == ProductContract.ProductStatus.Approved,
         	"product not approved"
         );
         require(
         	productInfo.ownerId == ownerAccount.did,
         	"must be product owner"
         );
         require(
         	ownerAccount.accountStatus ==
         	AccountContract.AccountStatus.Approved,
         	"owner not approved"
         );
         bytes32 tempHash = _hash;
         if(_hash == bytes32(0)){
         	// calculate hash for verify
         	string memory str = string(abi.encodePacked(productId,_contentJson,dataSchemaName));
         	tempHash = keccak256(abi.encodePacked(str));
         }
         require(hashToId[tempHash] == dataSchemaId,"data is not consistent");
     
         _createDataDetail(dataSchemaId,_contentJson, dataSchemaName);
     }
     ```

     > **说明：根据参数`_hash`判断该数据是否为仅自己可见，如果该参数不为默认的`bytes32(0)`，外部输入的`dataDetail`应该为加密后的数据**

   * `_createDataDetail()`函数具体实现如下：

     该函数用于保存data数据，并且响应`CreateDataDetailEvent()`事件

     ```solidity
     function _createDataDetail(
         bytes32 dataSchemaId,
         string memory _contentJson,
         string memory dataSchemaName
     )internal{
         dataDetails[dataSchemaId] = DataDetail(
         	dataSchemaName,
         	_contentJson
         );
         emit CreateDataDetailEvent(dataSchemaId,dataSchemaName,_contentJson);
     }
     ```

   * `getDataDetail()`函数具体实现如下：

     该函数通过`dataSchemaId`获取data数据

     ```solidity
     function getDataDetail(
     	bytes32 dataSchemaId
     ) external view returns(DataDetail memory){
     	return dataDetails[dataSchemaId];
     }
     ```

## 三、测试结果

> 由于数据手动输入较为麻烦，测试时通过后端ddcms_service调用

**测试1：**

回执返回结果如下：

`{"version":"0","contractAddress":"","checksumContractAddress":"","gasUsed":"61197","status":0,"blockNumber":"130","output":"0x","transactionHash":"0xcbdf573c1442cb1509e719326d857903905baff5ec22a72c81c6a66a4faef464","logEntries":[{"blockNumber":null,"address":"73fac4d3107689125edda50beb4ab3dbd0d9fdd0","topics":["0xc9d8a146b2304f772c63d0141eb80dc4c3ac5d0f3362602a54a0f2868fbe4445","0xc07af7a328323bcbea4bc4ef0432c5116ae6319306d529e20d36a8c83d1cb6d7"],"data":"0x00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000de6b58be8af95e695b0e68dae310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000027b7d000000000000000000000000000000000000000000000000000000000000"}],"input":"0x3ff9c06f0000000000000000000000000000000000000000000000000000000000000000ced875f32ddedf10e2e420756a66d3fee381e9c7ab35b00f0f2a1f289bd0a793c07af7a328323bcbea4bc4ef0432c5116ae6319306d529e20d36a8c83d1cb6d700000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000001310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000027b7d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000de6b58be8af95e695b0e68dae3100000000000000000000000000000000000000","from":"0x8f5d22545c9d9efe03b35d07da9a76e155f1a4ce","to":"0x73fac4d3107689125edda50beb4ab3dbd0d9fdd0","transactionProof":null,"receiptProof":null,"message":"","statusOK":true,"hash":"0x16daf451ef9ba4d51ce1cb2191f0212c134fccdc8ce2d219ce77d59f58d84669"}`

截图如下:

![微信图片_20230906150720.png](https://x.imgs.ovh/x/2023/09/06/64f8277bb0511.png)

---

**测试2：**

回执返回结果如下：

`{"version":"0","contractAddress":"","checksumContractAddress":"","gasUsed":"69627","status":0,"blockNumber":"132","output":"0x","transactionHash":"0x3e6369bf9acb7db07aea4144843a57440304f911dcea3dbedf2c0a54995ed11e","logEntries":[{"blockNumber":null,"address":"73fac4d3107689125edda50beb4ab3dbd0d9fdd0","topics":["0xc9d8a146b2304f772c63d0141eb80dc4c3ac5d0f3362602a54a0f2868fbe4445","0x23406c88c9d74f5cfd5af6979684d0bb693015762dda05ba88d753dc22d30e37"],"data":"0x000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000020373733303066326266393131386335343066346234356431623465373533393500000000000000000000000000000000000000000000000000000000000000203033653634373166343563623862303064343635393331363236353739646339"}],"input":"0x3ff9c06fca6bcdd715931374cded5757193536a0d340b4ad505b2d0cc28b246463408943ced875f32ddedf10e2e420756a66d3fee381e9c7ab35b00f0f2a1f289bd0a79323406c88c9d74f5cfd5af6979684d0bb693015762dda05ba88d753dc22d30e3700000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000000131000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020303365363437316634356362386230306434363539333136323635373964633900000000000000000000000000000000000000000000000000000000000000203737333030663262663931313863353430663462343564316234653735333935","from":"0x8f5d22545c9d9efe03b35d07da9a76e155f1a4ce","to":"0x73fac4d3107689125edda50beb4ab3dbd0d9fdd0","transactionProof":null,"receiptProof":null,"message":"","statusOK":true,"hash":"0xe4712fe81fbc46bbb0d418b39b35cdf1190aa4c0f94e3a09342c9afc1d6f9a27"}`

截图如下：

![c91374c32fea50aaa21c9b732e6cb08.png](https://x.imgs.ovh/x/2023/09/06/64f827a950ba7.png)