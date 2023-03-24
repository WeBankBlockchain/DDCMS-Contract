pragma solidity >0.8.0 <= 0.8.17;

import "./libs/IdGeneratorLib.sol";
import "./AccountContract.sol";

contract DataSchemaContract{
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
        uint256 threshold;
    }
    //status

    AccountContract private accountContract;
    mapping(bytes32 => DataSchemaInfo) dataSchemas;
    mapping(bytes32 => bytes32) private hashToId;
    mapping(bytes32 => uint256) private ownerDataSchemaCount;
    mapping(bytes32 => VoteInfo) private dataSchemaCreationVotes;
    mapping(bytes32=>mapping(bytes32 => bool)) private dataSchemaVoters;
    
    //constructor
    constructor(address _accountContract) {
        accountContract = AccountContract(_accountContract);
    }

    //functions
    function createDataSchema(bytes32 hash, bytes productId) external returns(bytes32 dataSchemaId){
        require(hash != bytes32(0), "Invalid hash");
        AccountContract.AccountData memory owner = accountContract.getAccountByAddress(msg.sender);
        require(owner.accountStatus == AccountContract.AccountStatus.Approved, "Address not approved");
        require(owner.accountType == AccountContract.AccountType.Company, "Account is not company");
        require(hashToId[hash] == 0, "duplicate data schema hash");
        //判断产品状态，owner等 
        
        uint256 ownerNonce = ownerDataSchemaCount[owner.did];
        //todo:用产品id
        dataSchemaId = IdGeneratorLib.generateId(owner.did, ownerNonce);
        dataSchemas[dataSchemaId] = DataSchemaInfo(hash, owner.did, DataSchemaStatus.Approving);
        hashToId[hash] = dataSchemaId;
        ownerNonce++;
        ownerDataSchemaCount[owner.did] = ownerNonce;
        uint256 witnessCount = accountContract.accountTypeNumbers(AccountContract.AccountType.Witness);
        dataSchemaCreationVotes[dataSchemaId] = VoteInfo(
            0, 
            0, 
            (witnessCount + 1) / 2
        );
        emit CreateDataSchema(dataSchemaId, hash);
    }


    function approveDataSchema(bytes32 dataSchemaId, bool agree) external return(DataSchemaStatus status){
        AccountContract.AccountData memory owner = accountContract.getAccountByAddress(msg.sender);
        require(owner.accountStatus == AccountContract.AccountStatus.Approved, "Address not approved");
        require(owner.accountType == AccountContract.AccountType.Witness, "Account is not witness");

        DataSchemaInfo storage dataSchema = dataSchemas[dataSchemaId];
        require(dataSchema.status == DataSchemaStatus.Approving, "Invalid data schema status");
        VoteInfo storage voteInfo = dataSchemaCreationVotes[dataSchemaId];
        require(!dataSchemaVoters[dataSchemaId][owner.did], "Duplicate vote");
        uint256 threshold = voteInfo.threshold;
        if (agree){
            uint256 agreeCount = voteInfo.agreeCount + 1;
            voteInfo.agreeCount = agreeCount;
            if (agreeCount >= threshold){
                dataSchema.status = DataSchemaStatus.Approved;
                emit DataSchemaApproved(dataSchemaId);
            }

        } else{
            uint256 denyCount = voteInfo.denyCount + 1;
            voteInfo.denyCount = denyCount;
            if (denyCount >= threshold){
                dataSchema.status = DataSchemaStatus.Denied;
                emit DataSchemaDenied(dataSchemaId);
            }
        }
        dataSchemaVoters[dataSchemaId][owner.did] = true;
        return dataSchema.status;
    }

    function getDataSchema(bytes32 dataSchemaId) external view returns(DataSchemaInfo memory){
        return dataSchemas[dataSchemaId];
    }

    function getVoteInfo(bytes32 dataSchemaId) external view returns(VoteInfo memory){
        return dataSchemaCreationVotes[productId];
    }
}