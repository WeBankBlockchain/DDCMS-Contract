pragma solidity >0.8.0 <= 0.8.17;

contract Ownable {
    event TransferOwnership(address oldOwner, address newOwner);
    address public owner;

    constructor(address _owner) {
        _transferOwnership(address(0), _owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Auth: invalid owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner{
        address oldOwner = owner;
        _transferOwnership(oldOwner, newOwner);
    }

    function _transferOwnership(address oldOwner, address newOwner) internal {
        owner = newOwner;
        emit TransferOwnership(oldOwner, newOwner);
    }
}