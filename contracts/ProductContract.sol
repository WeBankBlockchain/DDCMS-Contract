pragma solidity >0.8.0 <= 0.8.17;

import "./Ownable.sol";
import "./IAccountRegistration.sol";
import "./Common.sol";

contract ProductContract is Ownable, Common {
    // error
    error ProductAlreadyCreated(bytes32 hash);
    error ProductNotExisted(uint256 productId);
    error OnlyProductOwnerCanCall(uint256 productId);
    error ProductAudited(uint256 productId);
    // event
    event CreateProduct(uint256 indexed productId, bytes32 hash);
    event ModifyProduct(uint256 indexed productId, bytes32 hash);    
    event DeleteProduct(uint256 indexed productId);
    event ProductApproved(uint256 indexed productId);
    event ProductDenied(uint256 indexed productId);
    //enum && structs
    enum ProductStatus {
        NotExisted,
        Created,
        Approved,
        Denied
    }
    
    struct ProductInfo{
        bytes32 hash;
        address manager;
        ProductStatus status;
    }
    
    //status
    uint256 private idGenerator;
    IAccountRegistration private accountRegistration;
    mapping(uint256 => ProductInfo) products;
    mapping(bytes32 => uint256) private hashToId;
    
    //constructor
    constructor(address _owner, address accountContract) Ownable(_owner){
        accountRegistration = IAccountRegistration(accountContract);
    }

    //modifier

    //functions
    function createaProduct(bytes32 hash) external returns(uint256 productId){
        if (hash == bytes32(0)) {
            revert InvalidHash();
        }
        if(!accountRegistration.isAddressRegistered(msg.sender)) {
            revert IAccountRegistration.AddressNotRegistered(msg.sender);
        }
        if(hashToId[hash] != 0) {
            revert  ProductAlreadyCreated(hash);
        }
        
        productId = ++idGenerator;
        
        ProductInfo storage productInfo = products[productId];
        productInfo.hash = hash;
        productInfo.manager = msg.sender;
        productInfo.status = ProductStatus.Created;
        
        hashToId[hash] = productId;
        emit CreateProduct(productId, hash);
    }
    
    function modifyProduct(uint256 productId, bytes32 hash) external {
        ProductInfo storage product = products[productId];
        if (product.status == ProductStatus.NotExisted) {
            revert ProductNotExisted(productId);
        }
        if (msg.sender != product.manager) {
            revert OnlyManagerCanCall();
        }

        bytes32 prevHash = product.hash;
        product.hash = hash;

        delete hashToId[prevHash];
        hashToId[hash] = productId;
        
        emit ModifyProduct(productId, hash);
    }

    function deleteProduct(uint256 productId) external {
        ProductInfo storage product = products[productId];
        if (product.status == ProductStatus.NotExisted) {
            revert ProductNotExisted(productId);
        }
        if (msg.sender != product.manager) {
            revert OnlyManagerCanCall();
        }

        bytes32 prevHash = product.hash;
        delete products[productId];
        delete hashToId[prevHash];

        emit DeleteProduct(productId);
    }

    function approveProduct(uint256 productId, bool agree) external onlyOwner{
        ProductInfo storage product = products[productId];
        if (product.status == ProductStatus.NotExisted) {
            revert ProductNotExisted(productId);
        }
        if (product.status != ProductStatus.Created) {
            revert ProductAudited(productId);
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