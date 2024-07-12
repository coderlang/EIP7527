// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SimpleENSRegistry {
  mapping(bytes32 => address) public owners;
  mapping(bytes32 => address) public resolvers;

  function register(bytes32 label, address owner) public {
    require(owners[label] == address(0), "Label already owned");
    owners[label] = owner;
  }

  function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public {
    bytes32 subnode = keccak256(abi.encodePacked(node, label));
    require(owners[node] == msg.sender || owners[node] == address(0), string(abi.encodePacked("Caller (", toString(msg.sender), ") is not the owner (", toString(owners[node]), ")")));
    owners[subnode] = owner;
  }

  function setResolver(bytes32 node, address resolver) public {
    require(owners[node] == msg.sender, string(abi.encodePacked("Caller (", toString(msg.sender), ") is not the owner (", toString(owners[node]), ")")));
    resolvers[node] = resolver;
  }

  function transferOwnership(bytes32 label, address newOwner) public {
    require(owners[label] == msg.sender, string(abi.encodePacked("Caller (", toString(msg.sender), ") is not the owner (", toString(owners[label]), ")")));
    owners[label] = newOwner;
  }

  function toString(address _addr) internal pure returns (string memory) {
    bytes32 value = bytes32(uint256(uint160(_addr)));
    bytes memory alphabet = "0123456789abcdef";
    bytes memory str = new bytes(42);
    str[0] = '0';
    str[1] = 'x';
    for (uint256 i = 0; i < 20; i++) {
      str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
      str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
    }
    return string(str);
  }
}
