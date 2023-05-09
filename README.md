# Data-Brain简介

完整的项目请参考[Data-Brain介绍](https://github.com/WeBankBlockchain/Data-Brain)

# 项目构成
Data-Brain合约由三个部分构成：AccountContract、ProductContract、DataSchemaContract，分别管理账户、业务、数据目录。这里面的依赖关系为DataSchemaContract->ProductContract->AccountContract。 这是因为AccountContract记录了各个账户的身份，只有满足特定条件的身份才能进行目录和数据目录的创建、审核等操作；而数据目录隶属于某一业务，合约需要验证该关系。因此，在部署顺序上，需要先部署AccountContract，然后是ProductContract、DataSchemaContract。

# 如何使用
### 克隆代码
```
git clone https://github.com/WeBankBlockchain/Data-Brain-Contract.git
cd Data-Brain-Contract
git checkout origin/dev
```

### 链准备
首先需要有一条FISCO BCOS链，如果没有，可以部署一个。FISCO BCOS支持Air版、Pro版、Max版，对应不同的能力和复杂性，具体部署方式可以参考[链搭建文档](https://fisco-bcos-doc.readthedocs.io/zh_CN/latest/docs/tutorial/air/index.html#)。

接下来需要和FISCO BCOS交互，可以使用控制台或者webase。

### 私钥准备
只有可信第三方可以部署合约，所以需要一个可信第三方私钥，可以使用webase或者控制台生成，合约的部署均以可信第三方身份进行。

### 部署合约

然后，依次部署三个合约，以控制台为例，先将contracts目录下的合约拷贝到控制台contracts/solidity目录下，以可信第三方身份启动控制台后执行部署：
```
[group0]: /apps> deploy AccountContract
transaction hash: 0xade6832deb8f9641009336b955a3637bffbbc4fc9ffadb8a9de03ab6200f6093
contract address: 0x59fc2d7bbbb013ac9fc74a4c79bd25fdce02cba2
currentAccount: 0xcbe29631c0933c4319694dafc50723093f0de937

[group0]: /apps> deploy ProductContract 0x59fc2d7bbbb013ac9fc74a4c79bd25fdce02cba2
transaction hash: 0xefcc3503414490eb28dff330b9d42701bd1359f1fc784014f109ba16212fbfac
contract address: 0x24829babadbdc5fe4205353f6a2a6a79e7eef6a5
currentAccount: 0xcbe29631c0933c4319694dafc50723093f0de937

[group0]: /apps> deploy DataSchemaContract 0x59fc2d7bbbb013ac9fc74a4c79bd25fdce02cba2 0x24829babadbdc5fe4205353f6a2a6a79e7eef6a5
transaction hash: 0x27c43f0ca480a5f349205b2dcad6cc045ce4636ee4e41fbddfebb68b60104625
contract address: 0xa085baa5914e1d082c94ce24baf49473caa33ff1
currentAccount: 0xcbe29631c0933c4319694dafc50723093f0de937
```

其中：
- ProductContract部署参数为AccountContract地址，请替换为实际的地址
- DataSchemaContract部署参数为AccountContract地址和ProductContract地址，请替换为实际的地址

