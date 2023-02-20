pragma solidity >0.8.0 <= 0.8.17;

import "./Ownable.sol";
import "./IAccountRegistration.sol";
import "./Common.sol";

contract AccountContract is IAccountRegistration, Ownable, Common{

    // events
    event AccountRegistered(bytes32 did, address addr, AccountType accountType, bytes32 hash);
    event AccountApproved(bytes32 did);
    event AccountDenied(bytes32 did);
    // status
    mapping(address=>bytes32) private accountToDid;
    mapping(bytes32=>AccountData) private didToAccount;
    
    // enums && structs
    enum AccountStatus{
        UnRegistered, //0
        Registered, //1
        Approved, //2
        Denied //3
    }

    enum AccountType {
        NormalUser,
        Enterprise
    }
    

    struct AccountData{
        address addr;
        AccountStatus status;
        AccountType accountType;
        bytes32 hash;
    }
    
    // constructor
    constructor(address _owner) Ownable(_owner){

    }
    
    // external functions
    function register(bytes32 did, address addr, AccountType accountType, bytes32 hash) external{
        //check
        if (did == bytes32(0)){
            revert InvalidAccountId(did);
        }
        if (addr == address(0)){
            revert InvalidAddress();
        }
        if (hash == bytes32(0)){
            revert InvalidHash();
        }
        if (didToAccount[did].addr != address(0)) {
            revert AccountAlreadyExists(did);
        }
        if (accountToDid[addr] != bytes32(0)) {
            revert AddressAlreadyExists(addr);
        }
        
        //effects
        AccountData storage account = didToAccount[did];
        account.addr = addr;
        account.status = AccountStatus.Registered;
        account.accountType = accountType;
        account.hash = hash;
        
        emit AccountRegistered(did, addr, accountType, hash);
    }

    function approve(bytes32 did, bool agree) external onlyOwner {
        AccountData storage account = didToAccount[did];
        if (account.status == AccountStatus.UnRegistered) {
            revert AccountNotExist(did);
        }
        if (account.status != AccountStatus.Registered) {
            revert AccountAlreadyAudited(did);
        }
        if (agree){
            account.status = AccountStatus.Approved;
            emit AccountApproved(did);
        } else{
            account.status = AccountStatus.Denied;
            emit AccountDenied(did);
        }

    }

    function getAccountByDid(bytes32 did) external view returns(address addr, AccountStatus status, AccountType accountType, bytes32 hash) {
        AccountData storage account = didToAccount[did];
        addr = account.addr;
        status = account.status;
        accountType = account.accountType;
        hash = account.hash;
    }

    function getDidByAddress(address addr) external view returns(bytes32 did) {
        did = accountToDid[addr];
    }

    function isAddressRegistered(address addr) external override view returns(bool registered) {
        bytes32 did = accountToDid[addr];
        if (did == bytes32(0)) {
            registered = false;
        } else{
            AccountData storage accountData = didToAccount[did];
            registered  = accountData.status != AccountStatus.UnRegistered;  
        }
    }
}