# 简介
DDCMS-Contract用于追踪DDCMS的使用过程，数据目录生命周期中的每一个关键环节均会在链上留痕、存证，保证系统的可追溯、可监管。 它由三个模块构成：AccountContract, ProductContract, DataSchemaContract，由系统运营方部署。

- AccountContract: 负责账户管理，包括机构的注册、审核等功能。系统中的数据提供方、见证机构，均需要在AccountContract中注册并审核，才能使用Data-Brain。系统运营方则会在部署合约时自动注册。
- ProductContract: 负责业务管理，包括业务的创建、审核等功能。其中，业务的创建由数据提供方进行，其审核由见证方进行，当票数超过半数，即通过审核。
- DataSchemaContract：负责数据目录管理，包括数据目录的创建、审核等。其中，数据目录的创建由数据提供方进行，其审核由见证方进行，当票数超过半数，即通过审核。

具体内容请参考[使用手册](http://readthedocs.io)

## 贡献代码
欢迎参与本项目的社区建设：
- 如项目对您有帮助，欢迎点亮我们的小星星(点击项目右上方Star按钮)。
- 欢迎提交代码(Pull requests)。
- [提问和提交BUG](https://github.com/WeBankBlockchain/Data-Brain/issues)。
- 如果发现代码存在安全漏洞，请在[这里](https://security.webank.com)上报。


## License
![license](http://img.shields.io/badge/license-Apache%20v2-blue.svg)

开源协议为[Apache License 2.0](http://www.apache.org/licenses/). 详情参考[LICENSE](../LICENSE)。
