// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// TODO I need to figure out how to achive polymorphism the returning types (strings maybe and let the caller figure it out or something)
contract Oracle {
    event getValue(address indexed from, string what, uint256 id);

    constructor() {}

    function oracleQuery(string memory what, uint256 id) public {
        emit getValue(msg.sender, what, id);
    }
}