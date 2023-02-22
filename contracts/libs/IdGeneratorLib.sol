pragma solidity >0.8.0 <= 0.8.17;

library IdGeneratorLib {

    function generateId(bytes32 ownerId, uint256 ownerNonce) internal pure returns(bytes memory id){
        return abi.encode(ownerId, ownerNonce);
    }
}