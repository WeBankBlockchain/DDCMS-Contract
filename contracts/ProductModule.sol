pragma solidity >0.8.0 <= 0.8.17;

import "./GovernModule.sol";
import "./IAccountModule.sol";
import "./Common.sol";
import "./libs/IdGeneratorLib.sol";

contract ProductModule is Common, GovernModule{
    // error
    error ProductAlreadyCreated(bytes32 hash);
    error ProductNotExisted(bytes productId);
    error OnlyProductOwnerCanCall(bytes productId);
    error InvalidProductStatus(bytes productId);
    // event
    event CreateProduct(bytes indexed productId, bytes32 hash);
    event ModifyProduct(bytes indexed productId, bytes32 hash);    
    event DeleteProduct(bytes indexed productId);
    event ProductApproved(bytes indexed productId);
    event ProductDenied(bytes indexed productId);
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
    function createaProduct(bytes32 hash) external returns(bytes memory productId){
        if (hash == bytes32(0)) {
            revert InvalidHash();
        }
        IAccountModule.AccountData  memory owner = accountModule.getAccountByAddress(msg.sender);
        if(owner.status != IAccountModule.AccountStatus.Approved) {
            revert IAccountModule.InvalidAccountStatus(owner.did);
        }
        if(hashToId[hash].length != 0) {
            revert  ProductAlreadyCreated(hash);
        }
        
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
        if (product.status == ProductStatus.NotExisted) {
            revert ProductNotExisted(productId);
        }
        IAccountModule.AccountData memory owner = accountModule.getAccountByAddress(msg.sender);
        if (owner.did != product.owner) {
            revert InvalidCaller();
        }

        bytes32 prevHash = product.hash;
        product.hash = hash;

        delete hashToId[prevHash];
        hashToId[hash] = productId;
        
        emit ModifyProduct(productId, hash);
    }

    function deleteProduct(bytes calldata productId) external {
        ProductInfo storage product = products[productId];
        if (product.status == ProductStatus.NotExisted) {
            revert ProductNotExisted(productId);
        }
        IAccountModule.AccountData memory owner = accountModule.getAccountByAddress(msg.sender);
        if (owner.did != product.owner) {
            revert InvalidCaller();
        }

        bytes32 prevHash = product.hash;
        delete products[productId];
        delete hashToId[prevHash];

        emit DeleteProduct(productId);
    }

    function approveProduct(bytes calldata productId, bool agree) external onlyGovernor{
        ProductInfo storage product = products[productId];
        if (product.status == ProductStatus.NotExisted) {
            revert ProductNotExisted(productId);
        }
        if (product.status != ProductStatus.Created) {
            revert InvalidProductStatus(productId);
        }
        if (agree){
            product.status = ProductStatus.Approved;
            emit ProductApproved(productId);
        } else{
            product.status = ProductStatus.Denied;
            emit ProductDenied(productId);
        }
    }

}