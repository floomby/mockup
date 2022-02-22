// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "../deps/AccessControlEnumerable.sol";

abstract contract AeroName {
    string constant _aeroName = "Aero tokens";
}

contract Aero is ERC20Burnable, AeroName, AccessControlEnumerable {
    bytes32 public constant ROUTE_ROLE = keccak256("ROUTE_ROLE");
    bytes32 public constant AIRPORT_ROLE = keccak256("AIRPORT_ROLE");

    // The way this is written this needs to be deployed by the admin account which is needed for withdrawals
    constructor() ERC20(_aeroName, "AERO") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // _setupRole(ROUTE_ROLE, _msgSender());
        // _setupRole(AIRPORT_ROLE, _msgSender());
    }

    function setRouteAddress(address routeAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role to set route contract address");
        _setupRole(ROUTE_ROLE, routeAddress);
    }

    function setAirportAddress(address airportAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role to set airport contract address");
        _setupRole(AIRPORT_ROLE, airportAddress);
    }

    function burnFrom(address account, uint256 amount) public virtual override {
        address sender = _msgSender();
        if (!hasRole(ROUTE_ROLE, sender) && !hasRole(AIRPORT_ROLE, sender)) _spendAllowance(account, sender, amount);
        _burn(account, amount);
    }

    // TODO This is very much not the way we want to do it (locking the tokens to a existing cryptocurrency seems undesirerable)
    function purchase() public payable {
        _mint(_msgSender(), msg.value);
    }

    function withdraw() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Withdrawals only allowed by admin account");
        (bool success, ) = payable(_msgSender()).call{value: address(this).balance}("");
        require(success, "Failed to withdraw");
    }

    // TODO need a way to award aero to completed routes
}

contract CheckAero is AeroName {
    function isAeroContract(Aero aero) public view returns (bool) {
        return keccak256(abi.encodePacked((aero.name()))) == keccak256(abi.encodePacked((_aeroName)));
    }
}
