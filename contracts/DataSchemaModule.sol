pragma solidity >0.8.0 <= 0.8.17;

import "./libs/IdGeneratorLib.sol";
import "./AccountModule.sol";

contract ProductModule{
    // event
    event CreateDataSchema(bytes32 dataSchemaId, bytes32 hash); 
    event DataSchemaApproved(bytes32 dataSchemaId);
    event DataSchemaDenied(bytes32 dataSchemaId);
    //enum && structs
    enum DataSchemaStatus {
        Approving,
        Approved,
        Denied
    }
    
    struct DataSchemaInfo{
        bytes32 hash;
        bytes32 owner;
        DataSchemaStatus status;
    }
    
    struct VoteInfo {
        uint256 agreeCount;
        uint256 denyCount;
        mapping(bytes32=>bool) voters;
        uint256 threshold;
    }
    //status

    AccountModule private accountContract;
    mapping(bytes32 => DataSchemaInfo) dataSchemas;
    mapping(bytes32 => bytes32) private hashToId;
    mapping(bytes32 => uint256) private ownerDataSchemaCount;
    mapping(bytes32 => VoteInfo) private dataSchemaCreationVotes;
    
    //constructor
    constructor(address _accountContract) {
        accountContract = AccountModule(_accountContract);
    }

    //functions
    function createDataSchema(bytes32 hash) external returns(bytes32 dataSchemaId){
        require(hash != bytes32(0), "Invalid hash");
        AccountModule.AccountData owner = accountContract.getAccountByAddress(addr);
        require(owner.accountStatus == AccountType.Approved, "Address not approved");
        require(owner.accountType == AccountType.Company, "Account is not company");
        require(hashToId[hash] == 0, "duplicate data schema hash");
        
        
        uint256 ownerNonce = ownerDataSchemaCount[owner.did];
        dataSchemaId = IdGeneratorLib.generateId(owner.did, ownerNonce);
        dataSchemas[dataSchemaId] = DataSchema(hash, owner.did, DataSchemaStatus.Approving);
        hashToId[hash] = dataSchemaId;
        ownerNonce++;
        ownerDataSchemaCount[owner.did] = ownerNonce;
        
        dataSchemaCreationVotes[productId] = VoteInfo({
            threshold: accountContract.accountTypeNumbers(AccountType.Witness)
        });
        emit CreateDataSchema(dataSchemaId, hash);
    }


    function approveProduct(bytes32 dataSchemaId, bool agree) external{
        AccountModule.AccountData owner = accountContract.getAccountByAddress(addr);
        require(owner.accountStatus == AccountType.Approved, "Address not approved");
        require(owner.accountType == AccountType.Witness, "Account is not witness");

        DataSchemaInfo storage dataSchema = dataSchemas[dataSchemaId];
        require(dataSchema.status == DataSchemaStatus.Approving, "Invalid data schema status");
        VoteInfo storage voteInfo = dataSchemaCreationVotes[dataSchemaId];
        require(!voteInfo.voters[owner.did], "Duplicate vote");
        uint256 threshold = voteInfo.threshold;
        if (agree){
            uint256 agreeCount = voteInfo.agreeCount + 1;
            voteInfo.agreeCount = agreeCount;
            if (agreeCount >= threshold){
                product.status = DataSchemaStatus.Approved;
                emit DataSchemaApproved(productId);
            }

        } else{
            uint256 denyCount = voteInfo.denyCount + 1;
            voteInfo.denyCount = denyCount;
            if (denyCount >= threshold){
                product.status = DataSchemaStatus.Denied;
                emit DataSchemaDenied(productId);
            }
        }
        voteInfo.voters[owner.did] = true;
    }

}