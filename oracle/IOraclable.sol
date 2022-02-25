// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOraclable {
    function __callback(string memory, uint256) external;
}