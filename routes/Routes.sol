// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../deps/Context.sol";
import "../deps/Strings.sol";

import "../airports/ERC721PresetMinterPauserAutoId.sol";
import "../aero/Aero.sol";

import "../oraclinator/IOraclinatorable.sol";
import "../oraclinator/Oraclinator.sol";

// Having this be a erc721 is overkill probably
contract Route is ERC721PresetMinterPauserAutoId, CheckAero, IOraclinatorable {
    event routeAdded(uint256 tokenId);
    event log(string message);

    enum RouteType { EMERGENCY, COMMERCIAL, CARGO }
    enum AircraftType { JET, TURBOPROP, HELICOPTER }
    Aero private _aero;
    using Counters for Counters.Counter;

    address private _oraclinator;
    uint256 private _oracle_id;
    mapping(uint256 => address) private _routesInLimbo;

    struct RouteData {
        uint256 length;
        RouteType routeType;
        AircraftType aircraftType;
    }
    mapping(uint256 => RouteData) private _routeData;

    constructor(string memory baseURI, address aeroContractAddress, address oraclinator) ERC721PresetMinterPauserAutoId("Routes", "RTS", baseURI) {
        _aero = Aero(aeroContractAddress);
        require(isAeroContract(_aero), "Must provide a valid aero contract");
        _oraclinator = oraclinator;
    }

    function buyRoute() public {
        unchecked {
            // In principle we want this to wrap around even though it will never get to that point
            _oracle_id += 1;
        }
        _routesInLimbo[_oracle_id] = msg.sender;

        Oraclinator(_oraclinator).oraclinatorQuery("http://localhost:3000/prng", _oracle_id);
    }

    // We don't want routes to be minted like normal
    function mint(address /*to*/) public virtual override {
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory baseURI = _baseURI();
        RouteData memory data = _routeData[tokenId];
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(
            baseURI,
            "?length=",
            Strings.toString(data.length),
            "&routeType=",
            Strings.toString(uint256(data.routeType)),
            "&aircraftType=",
            Strings.toString(uint256(data.aircraftType))
        )) : "";
    }

    function __callback(string memory value, uint256 id) external {
        emit log(value);
        require(_routesInLimbo[id] != address(0), "Invalid route callback");
        uint256 tokenId = _tokenIdTracker.current();

        address sender = _routesInLimbo[id];
        _mint(sender, tokenId);
        // TODO somehow we need to set route properties (I just make something default for now)
        // Some of this could have an element of randomness, maybe you don't quite know if how good the route is and you are trying to get lucky
        _routeData[tokenId] = RouteData(42, RouteType.COMMERCIAL, AircraftType.JET);
        _tokenIdTracker.increment();
        // I think? a fail to burn will cause reversion even if we fail to burn cause out of gas (we aren't using call)
        // Idk I should look up exact behavior though to be sure
        _aero.burnFrom(sender, 100);
        emit routeAdded(tokenId);
    }
}