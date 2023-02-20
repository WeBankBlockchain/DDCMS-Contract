pragma solidity >0.8.0 <= 0.8.17;

interface IAccountRegistration {

    error AddressNotRegistered(address addr);
    error AddressAlreadyExists(address addr);
    error AccountAlreadyExists(bytes32 did);
    error AccountNotExist(bytes32 did);
    error AccountAlreadyAudited(bytes32 did);
    error InvalidAccountId(bytes32 did);
    
    function isAddressRegistered(address addr) external view returns(bool) ;
}