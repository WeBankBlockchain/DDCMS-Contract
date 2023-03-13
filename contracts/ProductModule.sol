pragma solidity >0.8.0 <= 0.8.17;

import "./GovernModule.sol";
import "./IAccountModule.sol";
import "./libs/IdGeneratorLib.sol";

contract ProductModule is  GovernModule{
    // event
    event CreateProduct(bytes productId, bytes32 hash);
    event ModifyProduct(bytes productId, bytes32 hash);    
    event DeleteProduct(bytes productId);
    event ProductApproved(bytes productId);
    event ProductDenied(bytes productId);
    //enum && structs
    enum ProductStatus {
        NotExisted,
        Created,
        Approved,
        Denied
    }
    
    struct ProductInfo{
        bytes32 hash;
        bytes32 owner;
        ProductStatus status;
    }
    
    //status
    //ID改为string:ownerId + owner自增id 

    IAccountModule private accountModule;
    mapping(bytes => ProductInfo) products;
    mapping(bytes32 => bytes) private hashToId;
    mapping(bytes32 => uint256) private ownerProductCount;
    
    //constructor
    constructor(address _governor, address accountContract) {
        address[] memory _governors = new address[](1);
        _governors[0] = _governor;
        _setupGovernors(_governors, GovernMode.Direct);
        accountModule = IAccountModule(accountContract);
    }

    //functions
    function createProduct(bytes32 hash) external returns(bytes memory productId){
        require(hash != bytes32(0), "Invalid hash");
        IAccountModule.AccountData  memory owner = accountModule.getAccountByAddress(msg.sender);
        require(owner.status == IAccountModule.AccountStatus.Approved, "invalid owner status");
        require(hashToId[hash].length == 0, "product already created");
        
        uint256 ownerNonce = ownerProductCount[owner.did];
        productId = IdGeneratorLib.generateId(owner.did, ownerNonce);
        products[productId] = ProductInfo(hash, owner.did, ProductStatus.Created);
        hashToId[hash] = productId;
        ownerNonce++;
        ownerProductCount[owner.did] = ownerNonce;
        
        emit CreateProduct(productId, hash);
    }
    
    function modifyProduct(bytes calldata productId, bytes32 hash) external {
        ProductInfo storage product = products[productId];
        require(product.status != ProductStatus.NotExisted, "product not existed");
        IAccountModule.AccountData memory owner = accountModule.getAccountByAddress(msg.sender);
        require(owner.did == product.owner, "caller not owner");

        bytes32 prevHash = product.hash;
        product.hash = hash;

        delete hashToId[prevHash];
        hashToId[hash] = productId;
        
        emit ModifyProduct(productId, hash);
    }

    function deleteProduct(bytes calldata productId) external {
        ProductInfo storage product = products[productId];
        require(product.status != ProductStatus.NotExisted, "product not existed");

        IAccountModule.AccountData memory owner = accountModule.getAccountByAddress(msg.sender);
        require(owner.did == product.owner, "caller not owner");

        bytes32 prevHash = product.hash;
        delete products[productId];
        delete hashToId[prevHash];

        emit DeleteProduct(productId);
    }

    function approveProduct(bytes calldata productId, bool agree) external onlyGovernor{
        ProductInfo storage product = products[productId];
        require(product.status == ProductStatus.Created, "invalid status");
        if (agree){
            product.status = ProductStatus.Approved;
            emit ProductApproved(productId);
        } else{
            product.status = ProductStatus.Denied;
            emit ProductDenied(productId);
        }
    }

}