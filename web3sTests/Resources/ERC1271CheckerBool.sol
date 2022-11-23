// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC1271CheckerBool is Ownable {

    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(_hash, _signature);
        require(error == ECDSA.RecoverError.NoError, "Invalid signature");
        if (recovered == owner()) {
            return true;
        } else {
            return false;
        }
    }
}
