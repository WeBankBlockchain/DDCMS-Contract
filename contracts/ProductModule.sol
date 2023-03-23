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
        Approving,
        Approved,
        Denied
    }
    
    struct ProductInfo{
        bytes32 hash;
        bytes32 owner;
        ProductStatus status;
    }
    
    struct VoteInfo {
        uint256 voteCount;
        
    }
    //status
    //ID改为string:ownerId + owner自增id 

    address private accountContract;
    mapping(bytes32 => ProductInfo) products;
    mapping(bytes32 => bytes) private hashToId;
    mapping(bytes32 => uint256) private ownerProductCount;
    mapping(bytes32 => uint256) private productCreationVotes;
    
    //constructor
    constructor(address _accountContract) {
        accountContract = _accountContract;
    }

    //functions
    function createProduct(bytes32 hash) external returns(bytes32 productId){
        require(hash != bytes32(0), "Invalid hash");
        IAccountModule.AccountData  memory owner = accountModule.getAccountByAddress(msg.sender);
        require(owner.status == IAccountModule.AccountStatus.Approved, "Owner must be registered, and approved");
        require(owner.accountType == IAccountModule.AccountType.Company, "Invalid account type");
        require(hashToId[hash].length == 0, "duplicate product hash");
        
        uint256 ownerNonce = ownerProductCount[owner.did];
        productId = IdGeneratorLib.generateId(owner.did, ownerNonce);
        products[productId] = ProductInfo(hash, owner.did, ProductStatus.Approving);
        hashToId[hash] = productId;
        ownerNonce++;
        ownerProductCount[owner.did] = ownerNonce;
        
        emit CreateProduct(productId, hash);
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