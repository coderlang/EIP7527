// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SimpleENSResolver {
    mapping(bytes32 => address) public addresses;

    event AddressSet(bytes32 indexed node, address addr);

    function setAddr(bytes32 node, address addr) external {
        addresses[node] = addr;
        emit AddressSet(node, addr);
    }

    function addr(bytes32 node) external view returns (address) {
        return addresses[node];
    }
}
