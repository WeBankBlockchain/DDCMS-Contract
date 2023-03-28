pragma solidity >0.8.0 <= 0.8.17;


contract AccountContract{
    //Events
    event AccountRegisteredEvent(bytes32 did, address addr, AccountType accountType, bytes32 hash);
    event AccountApprovedEvent(bytes32 did);
    event AccountDeniedEvent(bytes32 did);
    //Enums && structs
    enum AccountType {
        Person,//0 (预留)
        Company,//1
        Witness,//2
        Admin //3
    }
    
    enum AccountStatus{
        Approving,//0
        Approved, //1
        Denied, //2
        Disabled//3 (预留)封禁
    }

    struct AccountData{
        address addr;
        bytes32 did;
        AccountType accountType;
        AccountStatus accountStatus;
        bytes32 hash;
    }


    // status
    mapping(address=>bytes32) public addressToDid;
    mapping(bytes32=>AccountData) public didToAccount;
    mapping(AccountType=>uint256) public accountTypeNumbers;

    // modifier
    modifier onlyAdmin(){
        AccountData memory accountData = _getAccountByAddress(msg.sender);
        require(accountData.accountStatus == AccountStatus.Approved, "Invalid account status");
        require(accountData.accountType == AccountType.Admin, "Account are not admin");
        _;
    }

    // constructor
    constructor() {
        _register(msg.sender, AccountType.Admin, AccountStatus.Approved, bytes32(0));
    }
    
    // users functions
    function register(AccountType accountType, bytes32 hash) external returns (bytes32 did){
        //check
        require(hash != bytes32(0), "Invalid hash");
        address addr = msg.sender;
        require(addressToDid[addr] == bytes32(0), "address already registered");
        //effects
        did = _register(addr, accountType, AccountStatus.Approving, hash);
    }

    //Admin functions
    function approve(bytes32 did, bool agree) external onlyAdmin() {
        AccountData storage account = didToAccount[did];
        require(account.addr != address(0), "Account not exist");
        require(account.accountStatus == AccountStatus.Approving, "Invalid account status");
        if (agree){
            account.accountStatus = AccountStatus.Approved;
            accountTypeNumbers[account.accountType]++;
            emit AccountApprovedEvent(did);
        } else{
            account.accountStatus = AccountStatus.Denied;
            emit AccountDeniedEvent(did);
        }
    }

    //Query functions
    function getAccountByDid(bytes32 did) external view returns(AccountData memory) {
        return didToAccount[did];
    }

    function getAccountByAddress(address addr) external view returns(AccountData memory) {
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
        addressToDid[accountAddress] = did;
        didToAccount[did] = AccountData(accountAddress, did, accountType, accountStatus, hash);
        emit AccountRegisteredEvent(did, accountAddress, accountType, hash);
    }

    function _getAccountByAddress(address addr) internal view returns(AccountData memory) {
        bytes32 did = addressToDid[addr];
        require(did != 0, "address not registered");
        return didToAccount[did];
    }
}