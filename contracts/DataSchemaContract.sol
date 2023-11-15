pragma solidity >0.8.0 <=0.8.17;

import "./libs/IdGeneratorLib.sol";
import "./AccountContract.sol";
import "./ProductContract.sol";

contract DataSchemaContract {
    // event
    event CreateDataSchemaEvent(bytes32 dataSchemaId, bytes32 hash);
    event VoteDataSchemaEvent(
        bytes32 dataSchemaId,
        bytes32 voterId,
        bool agree,
        uint256 agreeCount,
        uint256 denyCount,
        DataSchemaStatus afterStatus
    );
    event CreateDataDetailEvent(bytes32 indexed dataSchemaId,string dataSchemaName,string contentJson);

    //enum && structs
    enum DataSchemaStatus {
        Approving,
        Approved,
        Denied,
        Disabled,
        Banned
    }

    struct DataSchemaInfo {
        bytes32 hash;
        bytes32 ownerId;
        bytes32 productId;
        DataSchemaStatus status;
    }

    struct VoteInfo {
        uint256 agreeCount;
        uint256 denyCount;
        uint256 threshold;
        uint256 witnessCount;
    }

    struct DataDetail {
        string dataSchemaName;
        string contentJson;
    }

    //status
    AccountContract private accountContract;
    ProductContract private productContract;
    mapping(bytes32 => DataSchemaInfo) dataSchemas;
    mapping(bytes32 => DataDetail) dataDetails;
    mapping(bytes32 => bytes32) private hashToId;
    mapping(bytes32 => uint256) private productDataSchemaCount;
    mapping(bytes32 => VoteInfo) private dataSchemaCreationVotes;
    mapping(bytes32 => mapping(bytes32 => bool)) private dataSchemaVoters;

    //constructor
    constructor(address _accountContract, address _productContract) {
        accountContract = AccountContract(_accountContract);
        productContract = ProductContract(_productContract);
    }

    //modifier
    modifier onlyWitness() {
        AccountContract.AccountData memory accountInfo = accountContract
            .getAccountByAddress(msg.sender);
        require(
            accountInfo.accountStatus == AccountContract.AccountStatus.Approved,
            "Invalid account status"
        );
        require(
            accountInfo.accountType == AccountContract.AccountType.Witness,
            "Account is not witness"
        );
        _;
    }

    //functions
    function createDataSchema(
        bytes32 hash,
        bytes32 productId
    ) external returns (bytes32 dataSchemaId, uint256 witnessCount) {
        //requires
        require(hash != bytes32(0), "Invalid hash");
        require(productId != bytes32(0), "Invalid productId");
        require(hashToId[hash] == 0, "duplicate data schema hash");
        //Get owner info
        AccountContract.AccountData memory ownerAccount = accountContract
            .getAccountByAddress(msg.sender);
        //Get product info
        ProductContract.ProductInfo memory productInfo = productContract
            .getProduct(productId);
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

        //Generate schema id
        uint256 productNonce = productDataSchemaCount[productId];
        dataSchemaId = IdGeneratorLib.generateId(productId, productNonce);
        dataSchemas[dataSchemaId] = DataSchemaInfo(
            hash,
            ownerAccount.did,
            productId,
            DataSchemaStatus.Approving
        );
        hashToId[hash] = dataSchemaId;
        productNonce++;
        productDataSchemaCount[productId] = productNonce;
        witnessCount = accountContract.accountTypeNumbers(
            AccountContract.AccountType.Witness
        );
        dataSchemaCreationVotes[dataSchemaId] = VoteInfo(
            0,
            0,
            witnessCount / 2 + 1,
            witnessCount
        );
        emit CreateDataSchemaEvent(dataSchemaId, hash);
    }

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

    function getDataDetail(
        bytes32 dataSchemaId
    ) external view returns(DataDetail memory){
        return dataDetails[dataSchemaId];
    }

    function approveDataSchema(
        bytes32 dataSchemaId,
        bool agree
    )
        external
        onlyWitness
        returns (
            bytes32 witnessDid,
            uint256 agreeCount,
            uint256 denyCount,
            DataSchemaStatus afterStatus
        )
    {
        //Arg validations
        require(dataSchemaId != 0, "Invalid data schema id");

        //Validation data schema status
        DataSchemaInfo storage dataSchema = dataSchemas[dataSchemaId];
        require(
            dataSchema.status == DataSchemaStatus.Approving,
            "Invalid data schema status"
        );

        //Vote
        AccountContract.AccountData memory witness = accountContract
            .getAccountByAddress(msg.sender);
        witnessDid = witness.did;
        VoteInfo storage voteInfo = dataSchemaCreationVotes[dataSchemaId];
        require(!dataSchemaVoters[dataSchemaId][witnessDid], "Duplicate vote");
        uint256 threshold = voteInfo.threshold;
        uint256 witnessCount = voteInfo.witnessCount;
        if (agree) {
            agreeCount = voteInfo.agreeCount + 1;
            voteInfo.agreeCount = agreeCount;
            denyCount = voteInfo.denyCount;
            if (agreeCount >= threshold) {
                afterStatus = DataSchemaStatus.Approved;
            }
        } else {
            denyCount = voteInfo.denyCount + 1;
            voteInfo.denyCount = denyCount;
            agreeCount = voteInfo.agreeCount;
            if (denyCount > (voteInfo.witnessCount - 1) / 2) {
                afterStatus = DataSchemaStatus.Denied;
            }
        }
        dataSchema.status = afterStatus;
        dataSchemaVoters[dataSchemaId][witnessDid] = true;
        emit VoteDataSchemaEvent(
            dataSchemaId,
            witnessDid,
            agree,
            agreeCount,
            denyCount,
            afterStatus
        );
    }

    function getDataSchema(
        bytes32 dataSchemaId
    ) external view returns (DataSchemaInfo memory dataSchema) {
        dataSchema = dataSchemas[dataSchemaId];
        require(dataSchema.ownerId != 0, "data schema not exist");
    }

    function getVoteInfo(
        bytes32 dataSchemaId
    ) external view returns (VoteInfo memory) {
        return dataSchemaCreationVotes[dataSchemaId];
    }

    function _requireAccount(
        address addr,
        AccountContract.AccountType accountType
    ) internal view {}
}
