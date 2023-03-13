pragma solidity >0.8.0 <= 0.8.17;

import "./GovernModule.sol";
import "./IAccountModule.sol";
import "./libs/IdGeneratorLib.sol";

contract DataSchemaModule is GovernModule{
    // errors
    error DataSchemaAlreadyExisted(bytes32 hash);
    error DataSchemaNotExisted(bytes dataSchemaId);

    // events
    event CreateDataSchema(bytes dataSchemaId, bytes32 hash, address manager);
    event ModifyDataSchema(bytes dataSchemaId, bytes32 hash);
    event DeleteDataSchema(bytes dataSchemaId);
    
    // structs
    struct DataSchema{
        bytes32 hash;
        bytes32 owner;
    }
    
    //status
    IAccountModule private accountModule;
    mapping(bytes => DataSchema) private dataSchemas;
    mapping(bytes32 => bytes) private hashToId;
    mapping(bytes32 => uint256) private ownerDataSchemaCount;
    //constructor
    constructor(address _governor, address accountContract) {
        address[] memory _governors = new address[](1);
        _governors[0] = _governor;
        _setupGovernors(_governors, GovernMode.Direct);
        accountModule = IAccountModule(accountContract);
    }

    //function
    function createDataSchema(bytes32 hash) external returns(bytes memory dataSchemaId){
        require(hash != bytes32(0), "invalid hash");
        require(hashToId[hash].length == 0, "data schema already existed");

        IAccountModule.AccountData  memory owner = accountModule.getAccountByAddress(msg.sender);
        require(owner.status == IAccountModule.AccountStatus.Approved, "invalid owner status");


        uint256 ownerNonce = ownerDataSchemaCount[owner.did];

        dataSchemaId = IdGeneratorLib.generateId(owner.did, ownerNonce);

        DataSchema storage dataSchema = dataSchemas[dataSchemaId];
        dataSchema.hash = hash;
        dataSchema.owner = owner.did;

        ownerNonce++;
        ownerDataSchemaCount[owner.did] = ownerNonce;
        emit CreateDataSchema(dataSchemaId, hash, msg.sender);
    }
    

    function modifyDataSchema(bytes calldata dataSchemaId, bytes32 hash) external{
        require(hash != bytes32(0), "invalid hash");
        
        DataSchema storage dataSchema = dataSchemas[dataSchemaId];
        require(dataSchema.owner != bytes32(0), "data schema not existed");

        IAccountModule.AccountData  memory owner = accountModule.getAccountByAddress(msg.sender);
        require(owner.did == dataSchema.owner, "caller not owner");

        
        bytes32 prevHash = dataSchema.hash;    
        dataSchema.hash = hash;
            
        delete hashToId[prevHash];
        hashToId[hash] = dataSchemaId;
            
        emit ModifyDataSchema(dataSchemaId, hash);
        
    }

    function deleteDataSchema(bytes calldata dataSchemaId) external  {
        DataSchema storage dataSchema = dataSchemas[dataSchemaId];
        
        require(dataSchema.owner != bytes32(0), "data schema not existed");
        
        IAccountModule.AccountData  memory owner = accountModule.getAccountByAddress(msg.sender);
        require(owner.did == dataSchema.owner, "caller not owner");

        

        bytes32 hash = dataSchema.hash;

        delete hashToId[hash];

        emit DeleteDataSchema(dataSchemaId);
    }

}