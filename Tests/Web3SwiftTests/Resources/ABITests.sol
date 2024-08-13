// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ABITests {

    event AddressAndData4Event(address indexed from, bytes4 indexed data);
    event AddressAndData32Event(address indexed from, bytes32 data);

    address[] private addresses;
    constructor() {
        addresses = [0x83f7338d17A85B0a0A8A1AE7Edead4dA571566E0];
    }
    function getDynamicArray() public view returns (address[] memory) {
        return addresses;
    }

    function callEventData4(address from) public {
        bytes32 hash = keccak256(abi.encodePacked(from));
        emit AddressAndData4Event(from, bytes4(hash));
        emit AddressAndData4Event(from, bytes4(0xdeadbeef));
    }

    function callEventData32(address from) public {
        bytes32 hash = keccak256(abi.encodePacked(from));
        emit AddressAndData32Event(from, hash);
    }
}
