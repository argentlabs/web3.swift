// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC1271Checker is IERC1271, Ownable {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal MAGICVALUE = 0x1626ba7e;

    constructor(address initialOwner) Ownable(initialOwner) {
        Ownable(initialOwner);
    

    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external override view returns (bytes4) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(_hash, _signature);
        require(error == ECDSA.RecoverError.NoError, "Invalid signature");
        if (recovered == owner()) {
            return MAGICVALUE;
        } else {
            return 0xffffffff;
        }
    }
}
