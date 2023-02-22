pragma solidity >0.8.0 <= 0.8.17;

contract GovernModule {

    event CreateProposal(bytes32 proposalId);
    event VoteProposal(bytes32 proposalId);
    event ExecuteProposal(bytes32 proposalId, bool success);
    event CancelProposal(bytes32 proposalId);
    
    mapping(address=>bool) private governors;
    uint256 private governorCount;
    GovernMode public mode;
    mapping(bytes32=>QueuedTransaction) private transactions;
    mapping(address=>uint256) nonces;
    
    enum GovernMode {
        Direct,
        Vote        
    }

    enum TransactionStatus {
        NotExist, 
        Created,
        Executed,
        Failed,
        Cancelled
    }
    
    struct QueuedTransaction {
        address from;
        address to;
        uint256 nonce;
        bytes data;    
        uint8 votes;
        TransactionStatus status;
    }


    
    modifier onlyGovernor() {
        if (msg.sender == address(this)){
            _;
            return;
        }
        _requireFromGovernors(msg.sender);
        if (mode == GovernMode.Direct){
            _;
            return;
        }
        if (mode == GovernMode.Vote) {
            _createProposal(msg.sender, address(this), nonces[msg.sender], msg.data);
        } 
    }


    modifier nonceChecker(uint256 passedNonce) {
        uint256 nonce = nonces[msg.sender];
        require(nonce== passedNonce, "Auth: Invalid nonce");
        _;
        nonces[msg.sender] = nonce+1;
    }
    //Initializer

    function _setupGovernors(address[] memory _governors, GovernMode _mode) internal {
        for (uint256 i=0;i<_governors.length;i++){
            governors[_governors[i]] = true;
        }
        mode = _mode;
        governorCount = _governors.length;
    }

    //Functions


    function createProposal( address to, uint256 nonce, bytes calldata data) public nonceChecker(nonce) returns(bytes32 proposalId) {
        _requireFromGovernors(msg.sender);
        proposalId = _createProposal(msg.sender, to, nonce, data);
    }

    function vote(bytes32 proposalId) external {
        _requireFromGovernors(msg.sender);
        QueuedTransaction memory transaction = transactions[proposalId];
        require(transaction.status == TransactionStatus.Created, "Invalid transaction status");
        transaction.votes++;
        if (transaction.votes * 2 >=  governorCount) {
            address to = transaction.to;
            bytes memory data = transaction.data;
            (bool success,) = to.call(data);
            transaction.status = success?TransactionStatus.Executed:TransactionStatus.Failed;
            emit ExecuteProposal(proposalId, success);
        }
        transactions[proposalId] = transaction;
        emit VoteProposal(proposalId);
    }

    function cancelProposal(bytes32 proposalId) external {
        _requireFromGovernors(msg.sender);
        QueuedTransaction storage transaction = transactions[proposalId];
        require(transaction.status == TransactionStatus.Created, "Invalid transaction status");
        transaction.status = TransactionStatus.Cancelled;
        emit VoteProposal(proposalId);
    }

    function _createProposal(address _from, address _to, uint256 _nonce, bytes calldata _data) internal returns(bytes32 _proposalId) {
        _proposalId = keccak256(abi.encodePacked(_from, _to, _nonce, _data));
        require(transactions[_proposalId].status == TransactionStatus.NotExist, "Transaction already exist");
        QueuedTransaction memory transaction = QueuedTransaction(_from, _to, _nonce, _data, 0, TransactionStatus.Created);
        transactions[_proposalId] = transaction;
        emit CreateProposal(_proposalId);
    }


    
    //Governor functions
    function changeMode(GovernMode newMode) external onlyGovernor{
        require(mode != newMode, "Invalid mode");
        mode = newMode;
    } 

    function addGovernor(address governor) external onlyGovernor{
        require(!governors[governor], "Governor already existed");
        governors[governor] = true;
        governorCount++;
    }

    function removeGovernor(address governor) external onlyGovernor{
        require(governors[governor], "Governor not existed");
        governors[governor] = false;
        governorCount--;      
    }

    //Helpers


    function _requireFromGovernors(address from) internal view {
        require(governors[from], "Gov: Invalid caller");
    }
}