// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";

contract Aero is ERC20Burnable {
    constructor(uint256 initialSupply) ERC20("Aero tokens", "AERO") {
        _mint(_msgSender(), initialSupply);
    }
}
