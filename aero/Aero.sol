// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "../AccessControlEnumerable.sol";

abstract contract AeroName {
    string constant _aeroName = "Aero tokens";
}

contract Aero is ERC20Burnable, AeroName, AccessControlEnumerable {
    bytes32 public constant ROUTE_ROLE = keccak256("ROUTE_ROLE");
    bytes32 public constant AIRPORT_ROLE = keccak256("AIRPORT_ROLE");

    constructor(uint256 initialSupply) ERC20(_aeroName, "AERO") {
        _mint(_msgSender(), initialSupply);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ROUTE_ROLE, _msgSender());
    }

    function setRouteAddress(address routeAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role to set route contract address");
        _setupRole(ROUTE_ROLE, routeAddress);
    }

    function setAirportAddress(address airportAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role to set airport contract address");
        _setupRole(AIRPORT_ROLE, airportAddress);
    }

    // This seems the wrong way to do this
    // function pay(address to, uint256 ammount) public {
    //     require(hasRole(ROUTE_ROLE, _msgSender()), "Must have route role to issue payment");
    //     _mint(to, ammount);
    // }

    function burnFrom(address account, uint256 amount) public virtual override {
        address sender = _msgSender();
        if (!hasRole(ROUTE_ROLE, sender) && !hasRole(AIRPORT_ROLE, sender)) _spendAllowance(account, sender, amount);
        _burn(account, amount);
    }

    // TODO Implement function to purchase aero
}

contract CheckAero is AeroName {
    function isAeroContract(Aero aero) public view returns (bool) {
        return keccak256(abi.encodePacked((aero.name()))) == keccak256(abi.encodePacked((_aeroName)));
    }
}
