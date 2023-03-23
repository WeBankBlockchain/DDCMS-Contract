pragma solidity >0.8.0 <= 0.8.17;

import "./libs/IdGeneratorLib.sol";
import "./AccountContract.sol";

contract ProductContract{
    // event
    event CreateProduct(bytes32 productId, bytes32 hash); 
    event ProductApproved(bytes32 productId);
    event ProductDenied(bytes32 productId);
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
        uint256 agreeCount;
        uint256 denyCount;
        uint256 threshold;
    }
    //status

    AccountContract private accountContract;
    mapping(bytes32 => ProductInfo) products;
    mapping(bytes32 => bytes32) private hashToId;
    mapping(bytes32 => uint256) private ownerProductCount;
    mapping(bytes32 => VoteInfo) private productCreationVotes;
    mapping(bytes32=>mapping(bytes32=>bool)) private productVoters;
    
    //constructor
    constructor(address _accountContract) {
        accountContract = AccountContract(_accountContract);
    }

    //functions
    function createProduct(bytes32 hash) external returns(bytes32 productId){
        //request
        require(hash != bytes32(0), "Invalid hash");
        AccountContract.AccountData memory owner = accountContract.getAccountByAddress(msg.sender);
        require(owner.accountStatus == AccountContract.AccountStatus.Approved, "Address not approved");
        require(owner.accountType == AccountContract.AccountType.Company, "Account is not company");
        require(hashToId[hash] == 0, "duplicate product hash");
        
        uint256 ownerNonce = ownerProductCount[owner.did];
        productId = IdGeneratorLib.generateId(owner.did, ownerNonce);
        products[productId] = ProductInfo(hash, owner.did, ProductStatus.Approving);
        hashToId[hash] = productId;
        ownerNonce++;
        ownerProductCount[owner.did] = ownerNonce;
        
        productCreationVotes[productId] = VoteInfo(
            0,
            0,
            accountContract.accountTypeNumbers(AccountContract.AccountType.Witness)
        );
        emit CreateProduct(productId, hash);
    }


    function approveProduct(bytes32 productId, bool agree) external{
        AccountContract.AccountData memory owner = accountContract.getAccountByAddress(msg.sender);
        require(owner.accountStatus == AccountContract.AccountStatus.Approved, "Address not approved");
        require(owner.accountType == AccountContract.AccountType.Witness, "Account is not witness");
        ProductInfo storage product = products[productId];
        require(product.status == ProductStatus.Approving, "Invalid product status");
        VoteInfo storage voteInfo = productCreationVotes[productId];
        require(!productVoters[productId][owner.did], "Duplicate vote");
        uint256 threshold = voteInfo.threshold;
        if (agree){
            uint256 agreeCount = voteInfo.agreeCount + 1;
            voteInfo.agreeCount = agreeCount;
            if (agreeCount >= threshold){
                product.status = ProductStatus.Approved;
                emit ProductApproved(productId);
            }

        } else{
            uint256 denyCount = voteInfo.denyCount + 1;
            voteInfo.denyCount = denyCount;
            if (denyCount >= threshold){
                product.status = ProductStatus.Denied;
                emit ProductDenied(productId);
            }
        }
        productVoters[productId][owner.did] = true;
    }

}