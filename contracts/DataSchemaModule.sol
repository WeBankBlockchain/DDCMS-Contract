pragma solidity >0.8.0 <= 0.8.17;

import "./GovernModule.sol";
import "./IAccountModule.sol";
import "./Common.sol";
import "./libs/IdGeneratorLib.sol";

contract DataSchemaModule is GovernModule, Common{
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
        if (hash == bytes32(0)){
            revert InvalidHash();
        }
        if(hashToId[hash].length != 0){
            revert DataSchemaAlreadyExisted(hash);
        }
        IAccountModule.AccountData  memory owner = accountModule.getAccountByAddress(msg.sender);
        if(owner.status != IAccountModule.AccountStatus.Approved) {
            revert IAccountModule.InvalidAccountStatus(owner.did);
        }

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
        if (hash == bytes32(0)){
            revert InvalidHash();
        }
        
        DataSchema storage dataSchema = dataSchemas[dataSchemaId];
        if (dataSchema.owner == bytes32(0)){
            revert DataSchemaNotExisted(dataSchemaId);
        }
        IAccountModule.AccountData  memory owner = accountModule.getAccountByAddress(msg.sender);
        if (dataSchema.owner != owner.did){
            revert InvalidCaller();
        }
        
        bytes32 prevHash = dataSchema.hash;    
        dataSchema.hash = hash;
            
        delete hashToId[prevHash];
        hashToId[hash] = dataSchemaId;
            
        emit ModifyDataSchema(dataSchemaId, hash);
        
    }

    function deleteDataSchema(bytes calldata dataSchemaId) external  {
        DataSchema storage dataSchema = dataSchemas[dataSchemaId];

        if (dataSchema.owner == bytes32(0)){
            revert DataSchemaNotExisted(dataSchemaId);
        }
        
        IAccountModule.AccountData  memory owner = accountModule.getAccountByAddress(msg.sender);
        if (dataSchema.owner != owner.did){
            revert InvalidCaller();
        }
        

        bytes32 hash = dataSchema.hash;

        delete hashToId[hash];

        emit DeleteDataSchema(dataSchemaId);
    }

}