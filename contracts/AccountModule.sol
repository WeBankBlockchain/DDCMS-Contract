pragma solidity >0.8.0 <= 0.8.17;

import "./GovernModule.sol";
import "./IAccountModule.sol";

contract AccountModule{
    //Enums && structs
    enum AccountType {
        Person,//0
        Company,//1
        Witness,//2
        Admin //3
    }
    
    enum AccountStatus{
        Approving,//0
        Approved, //1
        Denied //2
    }

    struct AccountData{
        address addr;
        AccountType accountType;
        AccountStatus status;
        bytes32 hash;
    }


    // status
    mapping(address=>bytes32) private addressToDid;
    mapping(bytes32=>AccountData) private didToAccount;

    // constructor
    constructor() {
        _register(msg.sender, AccountType.Admin, AccountStatus.Approved, bytes32(0));
    }
    
    //Admin functions
    function setupAccounts(address[] calldata addrs, AccountType[] calldata accountTypes, bytes32[] calldata hashes) external {
        _requireOnlyAdmin(msg.sender);
        require(addrs.length == accountTypes.length, "addrs and accountTypes length not match");
        require(addrs.length == hashes.length, "addrs and hashes length not match");
        uint256 n = addrs.length;
        for(uint256 i=0;i<n;i++) {
            address addr = addrs[i];
            _register(addr, accountTypes[i], AccountStatus.Approved, hashes[i]);
        }
    }

    function approve(bytes32 did, bool agree) external {
        _requireOnlyAdmin(msg.sender);
        AccountData storage account = didToAccount[did];
        require(account.status == AccountStatus.Approving, "Invalid account status");
        if (agree){
            account.status = AccountStatus.Approved;
            emit AccountApproved(did);
        } else{
            account.status = AccountStatus.Denied;
            emit AccountDenied(did);
        }
    }
    
    // users functions
    function register(bytes32 hash) external returns (bytes32 did){
        //check
        require(hash != bytes32(0), "Invalid hash");
        address addr = msg.sender;
        require(addressToDid[addr] == bytes32(0), "address already registered");
        
        //effects
        did = _register(addr, AccountType.Company, AccountStatus.Approving, hash);
    }


    //Query functions
    function getAccountByDid(bytes32 did) external view returns(AccountData memory) {
        return didToAccount[did];
    }

    function getAccountByAddress(address addr) external override view returns(AccountData memory) {
        return _getAccountByAddress(addr);
    }


    //Internal functions 
    function _generateDid(AccountType userType, address initAddr, bytes32 hash) internal pure returns(bytes32 id){
        uint256 header = uint256(userType) << 240; //header
        uint256 body = (uint256(keccak256(abi.encodePacked(initAddr, hash))) << 16) >> 16;
        id = bytes32(header | body);        
    }

    function _register(address accountAddress, AccountType accountType, AccountStatus accountStatus, bytes32 hash) internal returns(bytes32 did) {
        did = _generateDid(accountType, accountAddress, hash);
        addressToDid[addr] = did;
        didToAccount[did] = AccountData(accountAddress, accountType, accountStatus, hash);
        emit AccountRegistered(did, accountAddress, accountType, hash);
    }

    function _getAccountByAddress(address addr) external override view returns(AccountData memory) {
        bytes32 did = addressToDid[addr];
        require(did != 0, "address not registered");
        return didToAccount[did];
    }

    function _requireOnlyAdmin(address addr) external override {
        AccountData memory accountData = _getAccountByAddress(addr);
        require(accountData.accountStatus == AccountType.Approved, "Only approved user can call");
        require(accountData.accountType == AccountType.Admin, "Only admin can call");
    }
}