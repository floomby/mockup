// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "../AccessControlEnumerable.sol";

abstract contract AeroName {
    string constant _aeroName = "Aero tokens";
}

contract Aero is ERC20Burnable, AeroName, AccessControlEnumerable {
    bytes32 public constant ROUTE_ROLE = keccak256("MINTER_ROLE");

    constructor(uint256 initialSupply) ERC20(_aeroName, "AERO") {
        _mint(_msgSender(), initialSupply);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ROUTE_ROLE, _msgSender());
    }

    function setRouteAddress(address routeAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role to set route contract address");
        _setupRole(ROUTE_ROLE, routeAddress);
    }

    function pay(address to, uint256 ammount) public {
        require(hasRole(ROUTE_ROLE, _msgSender()), "Must have route role to issue payment");
        _mint(to, ammount);
    }

    // TODO Implement function to purchase aero
}

contract CheckAero is AeroName {
    function isAeroContract(Aero aero) public view returns (bool) {
        return keccak256(abi.encodePacked((aero.name()))) == keccak256(abi.encodePacked((_aeroName)));
    }
}
