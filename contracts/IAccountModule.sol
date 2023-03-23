pragma solidity >0.8.0 <= 0.8.17;

interface IAccountModule {

    event AccountRegistered(bytes32 did, address addr, AccountType accountType, bytes32 hash);
    event AccountApproved(bytes32 did);
    event AccountDenied(bytes32 did);
    



    function getAccountByAddress(address addr) external view returns(AccountData memory);
}