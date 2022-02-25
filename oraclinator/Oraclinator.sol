// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// TODO I need to figure out how to achive polymorphism the returning types (strings maybe and let the caller figure it out or something)
contract Oraclinator {
    event getValue(address indexed from, string what, uint256 id);

    mapping(address => uint256) private _deposits;
    address payable private _owner;
    uint256 _price;

    constructor() {
        _owner = payable(msg.sender);
    }

    function deposit() payable public {
        _deposits[msg.sender] += msg.value;
    }

    function withdraw() public {
        require(msg.sender == _owner, "Withdrawals only allowed by contract deployer");
        _owner.transfer(address(this).balance);
    }

    function oraclinatorQuery(string memory what, uint256 id) public {
        emit getValue(msg.sender, what, id);
    }
}