pragma solidity >0.8.0 <=0.8.17;

import "./libs/IdGeneratorLib.sol";
import "./AccountContract.sol";

contract ProductContract {
    // event
    event CreateProductEvent(bytes32 productId, bytes32 hash);
    event VoteProductEvent(
        bytes32 productId,
        bytes32 voterId,
        bool agree,
        uint256 agreeCount,
        uint256 denyCount,
        ProductStatus afterStatus
    );
    //enum && structs
    enum ProductStatus {
        Approving,
        Approved,
        Denied,
        Disabled,
        Banned
    }

    struct ProductInfo {
        bytes32 hash;
        bytes32 ownerId;
        ProductStatus status;
    }

    struct VoteInfo {
        uint256 agreeCount;
        uint256 denyCount;
        uint256 threshold;
        uint256 witnessCount;
    }

    //status
    AccountContract private accountContract;
    mapping(bytes32 => ProductInfo) products;
    mapping(bytes32 => bytes32) private hashToId;
    mapping(bytes32 => uint256) private ownerProductCount;
    mapping(bytes32 => VoteInfo) private productCreationVotes;
    mapping(bytes32 => mapping(bytes32 => bool)) public productVoters;

    //company modifier
    modifier onlyCompany() {
        _requireAccount(msg.sender, AccountContract.AccountType.Company);
        _;
    }

    //witness modifier
    modifier onlyWitness() {
        _requireAccount(msg.sender, AccountContract.AccountType.Witness);
        _;
    }

    //constructor
    constructor(address _accountContract) {
        accountContract = AccountContract(_accountContract);
    }

    //functions
    function createProduct(
        bytes32 hash
    ) external onlyCompany returns (bytes32 productId, uint256 witnessCount) {
        //requires
        require(hash != bytes32(0), "Invalid hash");
        require(hashToId[hash] == 0, "duplicate product hash");

        //Generate product id
        AccountContract.AccountData memory owner = accountContract
            .getAccountByAddress(msg.sender);

        uint256 ownerNonce = ownerProductCount[owner.did];
        productId = IdGeneratorLib.generateId(owner.did, ownerNonce);
        products[productId] = ProductInfo(
            hash,
            owner.did,
            ProductStatus.Approving
        );
        hashToId[hash] = productId;
        ownerNonce++;
        ownerProductCount[owner.did] = ownerNonce;

        //Initialize voting params
        witnessCount = accountContract.accountTypeNumbers(
            AccountContract.AccountType.Witness
        );
        productCreationVotes[productId] = VoteInfo(
            0,
            0,
            witnessCount / 2 + 1,
            witnessCount
        );
        emit CreateProductEvent(productId, hash);
    }

    function approveProduct(
        bytes32 productId,
        bool agree
    )
        external
        onlyWitness
        returns (
            bytes32 witnessDid,
            uint256 agreeCount,
            uint256 denyCount,
            ProductStatus afterStatus
        )
    {
        //Product id validation
        ProductInfo storage product = products[productId];
        require(product.ownerId != bytes32(0), "product not existed");
        require(
            product.status == ProductStatus.Approving,
            "Invalid product status"
        );
        VoteInfo storage voteInfo = productCreationVotes[productId];

        //Vote
        AccountContract.AccountData memory witness = accountContract
            .getAccountByAddress(msg.sender);
        witnessDid = witness.did;
        require(!productVoters[productId][witnessDid], "Duplicate vote");
        uint256 threshold = voteInfo.threshold;
        if (agree) {
            agreeCount = voteInfo.agreeCount + 1;
            voteInfo.agreeCount = agreeCount;
            denyCount = voteInfo.denyCount;
            if (agreeCount >= threshold) {
                afterStatus = ProductStatus.Approved;
            }
        } else {
            denyCount = voteInfo.denyCount + 1;
            voteInfo.denyCount = denyCount;
            agreeCount = voteInfo.agreeCount;
            if (denyCount > (voteInfo.witnessCount - 1) / 2) {
                afterStatus = ProductStatus.Denied;
            }
        }
        product.status = afterStatus;
        productVoters[productId][witnessDid] = true;
        //event
        emit VoteProductEvent(
            productId,
            witnessDid,
            agree,
            agreeCount,
            denyCount,
            afterStatus
        );
    }

    function getProduct(
        bytes32 productId
    ) external view returns (ProductInfo memory productInfo) {
        productInfo = products[productId];
        require(productInfo.ownerId != 0, "Product not exist");
    }

    function getVoteInfo(
        bytes32 productId
    ) external view returns (VoteInfo memory) {
        return productCreationVotes[productId];
    }

    function _requireAccount(
        address addr,
        AccountContract.AccountType accountType
    ) internal view {
        AccountContract.AccountData memory accountInfo = accountContract
            .getAccountByAddress(addr);
        require(
            accountInfo.accountStatus == AccountContract.AccountStatus.Approved,
            "Invalid account status"
        );
        require(
            accountInfo.accountType == accountType,
            "Account is not witness"
        );
    }
}
