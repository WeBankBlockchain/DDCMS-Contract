pragma solidity >0.8.0 <= 0.8.17;

import "./GovernModule.sol";
import "./IAccountModule.sol";
import "./Common.sol";

contract AccountModule is IAccountModule, GovernModule, Common{


    // status
    mapping(address=>bytes32) private addressToDid;
    mapping(bytes32=>AccountData) private didToAccount;
    

    // constructor
    constructor(address _governor) {
        address[] memory _governors = new address[](1);
        _governors[0] =_governor;
        _setupGovernors(_governors, GovernMode.Direct);
    }
    
    // //todo: did generated in contract
    // // external functions
    function register(address addr, AccountType accountType, bytes32 hash) external returns (bytes32 did){
        //check
        if (addr == address(0)){
            revert InvalidAddress();
        }

        if (addressToDid[addr] != bytes32(0)) {
            revert AddressAlreadyExists(addr);
        }
        //effects
        did = _generateDid(accountType, addr, hash);
        addressToDid[addr] = did;
        didToAccount[did] = AccountData(did, addr, AccountStatus.Registered, accountType, hash);
        
        emit AccountRegistered(did, addr, accountType, hash);
    }

    function approve(bytes32 did, bool agree) external onlyGovernor {
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

    function getAccountByDid(bytes32 did) external view returns(AccountData memory) {
        return didToAccount[did];
    }

    function getAccountByAddress(address addr) external override view returns(AccountData memory) {
        bytes32 did = addressToDid[addr];
        if (did == 0){
            revert AddressNotRegistered(addr);
        }
        return didToAccount[did];
    }


    function _generateDid(AccountType userType, address initAddr, bytes32 hash) internal pure returns(bytes32 id){
        uint256 header = uint256(userType) << 240; //header
        uint256 body = (uint256(keccak256(abi.encodePacked(initAddr, hash))) << 16) >> 16;
        id = bytes32(header | body);        
    }
}