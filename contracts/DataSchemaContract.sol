pragma solidity >0.8.0 <= 0.8.17;

import "./Ownable.sol";
import "./IAccountRegistration.sol";
import "./Common.sol";

contract DataSchemaContract is Ownable, Common{
    // errors
    error DataSchemaAlreadyExisted(bytes32 hash);
    error DataSchemaNotExisted(uint256 productId);

    // events
    event CreateDataSchema(uint256 dataSchemaId, bytes32 hash, address manager);
    event ModifyDataSchema(uint256 dataSchemaId, bytes32 hash);
    event DeleteDataSchema(uint256 dataSchemaId);
    
    // structs
    struct DataSchema{
        bytes32 hash;
        address manager;
    }
    
    //status
    uint256 private idGenerator;
    IAccountRegistration private accountRegistration;
    mapping(uint256 => DataSchema) private dataSchemas;
    mapping(bytes32 => uint256) private hashToId;

    //modifier 


    //constructor
    constructor(address _owner, address accountContract) Ownable(_owner){
        accountRegistration = IAccountRegistration(accountContract);
    }

    //function
    function createDataSchema(bytes32 hash) external {
        if (hash == bytes32(0)){
            revert InvalidHash();
        }
        if(hashToId[hash] != 0){
            revert DataSchemaAlreadyExisted(hash);
        }
        if(!accountRegistration.isAddressRegistered(msg.sender)) {
            revert IAccountRegistration.AddressNotRegistered(msg.sender);
        }
        uint256 schemaId = ++idGenerator;
        DataSchema storage dataSchema = dataSchemas[schemaId];
        dataSchema.hash = hash;
        dataSchema.manager = msg.sender;

        emit CreateDataSchema(schemaId, hash, msg.sender);
    }
    

    function modifyDataSchema(uint256 schemaId, bytes32 hash) external{
        if (hash == bytes32(0)){
            revert InvalidHash();
        }
        
        DataSchema storage dataSchema = dataSchemas[schemaId];
        if (dataSchema.manager == address(0)){
            revert DataSchemaNotExisted(schemaId);
        }

        if (dataSchema.manager != msg.sender){
            revert OnlyManagerCanCall();
        }
        
        bytes32 prevHash = dataSchema.hash;    
        dataSchema.hash = hash;
            
        delete hashToId[prevHash];
        hashToId[hash] = schemaId;
            
        emit ModifyDataSchema(schemaId, hash);
        
    }

    function deleteDataSchema(uint256 schemaId) external  {
        DataSchema storage dataSchema = dataSchemas[schemaId];

        if (dataSchema.manager == address(0)){
            revert DataSchemaNotExisted(schemaId);
        }
        
        if (dataSchema.manager != msg.sender){
            revert OnlyManagerCanCall();
        }

        bytes32 hash = dataSchema.hash;

        delete hashToId[hash];

        emit DeleteDataSchema(schemaId);
    }

}