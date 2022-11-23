//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface Gateway {
  function resolveL2Address(bytes32 node) external view returns(address);
}

error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

contract DummyOffchainResolver {

  string[] public _urls;

  /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
  constructor(
    string[] memory urls
  ) {
      _urls = urls;
  }

  function setUrls(string[] memory urls_) external {
    _urls = urls_;
  }

  function validateENS(bytes calldata result, bytes calldata) external pure returns(address) {
    address resolved = abi.decode(result, (address));
    return resolved;
  }

  function resolver(bytes32 node) public view returns (address) {
      revert OffchainLookup(
            address(this),
            _urls,
            abi.encodeWithSelector(Gateway.resolveL2Address.selector, node),
            DummyOffchainResolver.validateENS.selector,
            ""
        );
  }
}
