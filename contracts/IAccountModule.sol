pragma solidity >0.8.0 <= 0.8.17;

interface IAccountModule {

    event AccountRegistered(bytes32 did, address addr, AccountType accountType, bytes32 hash);
    event AccountApproved(bytes32 did);
    event AccountDenied(bytes32 did);

    error AddressNotRegistered(address addr);
    error AddressAlreadyExists(address addr);
    error AccountAlreadyExists(bytes32 did);
    error AccountNotExist(bytes32 did);
    error AccountAlreadyAudited(bytes32 did);
    error InvalidAccountId(bytes32 did);
    error InvalidAccountStatus(bytes32 did);
    

    enum AccountType {
        NormalUser,
        Enterprise
    }
    
    enum AccountStatus{
        UnRegistered, //0
        Registered, //1
        Approved, //2
        Denied //3
    }

    struct AccountData{
        bytes32 did;
        address addr;
        AccountStatus status;
        AccountType accountType;
        bytes32 hash;
    }

    function getAccountByAddress(address addr) external view returns(AccountData memory);
}