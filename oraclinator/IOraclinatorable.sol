// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOraclinatorable {
    function __callback(string memory, uint256) external;
}