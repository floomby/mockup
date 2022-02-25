// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../deps/Context.sol";
import "../deps/Strings.sol";

import "../airports/ERC721PresetMinterPauserAutoId.sol";
import "../aero/Aero.sol";

import "../oracle/IOraclable.sol";
import "../oracle/Oracle.sol";

// Having this be a erc721 is overkill probably
contract Route is ERC721PresetMinterPauserAutoId, CheckAero, IOraclable {
    event routeAdded(uint256 tokenId);
    event log(string message);

    enum RouteType { EMERGENCY, COMMERCIAL, CARGO }
    enum AircraftType { JET, TURBOPROP, HELICOPTER }
    Aero private _aero;
    using Counters for Counters.Counter;

    address private _oracle;
    address private _oracleCallbackAddress;
    uint256 private _oracle_id;
    mapping(uint256 => address) private _routesInLimbo;

    struct RouteData {
        uint256 length;
        RouteType routeType;
        AircraftType aircraftType;
    }
    mapping(uint256 => RouteData) private _routeData;

    constructor(string memory baseURI, address aeroContractAddress, address oracle, address oracleCallbackAddress) 
        ERC721PresetMinterPauserAutoId("Routes", "RTS", baseURI) {
        _aero = Aero(aeroContractAddress);
        require(isAeroContract(_aero), "Must provide a valid aero contract");
        _oracle = oracle;
        _oracleCallbackAddress = oracleCallbackAddress;
    }

    function buyRoute() public {
        unchecked {
            // In principle we want this to wrap around even though it will never get to that point
            _oracle_id += 1;
        }
        _routesInLimbo[_oracle_id] = msg.sender;

        Oracle(_oracle).oracleQuery("http://localhost:3000/prng", _oracle_id);
        // To test concurrent transactions
        // Oracle(_oracle).oracleQuery("http://localhost:3000/prng", _oracle_id);
        // Oracle(_oracle).oracleQuery("http://localhost:3000/prng", _oracle_id);
        // Oracle(_oracle).oracleQuery("http://localhost:3000/prng", _oracle_id);
        // Oracle(_oracle).oracleQuery("http://localhost:3000/prng", _oracle_id);
    }

    function stringToUint32(string memory str) pure private returns (uint32 result) {
        bytes memory bts = bytes(str);
        uint32 i;
        result = 0;
        for (i = 0; i < bts.length; i++) {
            uint32 c = uint32(uint8(bts[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
    }

    // I grabbed the parameters from a table on https://en.wikipedia.org/wiki/Linear_congruential_generator
    // The domain matches the output of the prng in the backend so doing this is fine (all we care about is the statistics of this anyways)
    function nextLcgValue(uint32 value) pure private returns (uint32) {
        unchecked {
            return value * 1664525 + 1013904223;
        }
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
        require(msg.sender == _oracleCallbackAddress, "Callback called from invalid callback address");
        emit log(value);
        require(_routesInLimbo[id] != address(0), "Invalid route callback");

        uint32 num1 = stringToUint32(value);
        uint32 num2 = nextLcgValue(num1);
        uint32 num3 = nextLcgValue(num2);

        uint256 tokenId = _tokenIdTracker.current();

        address sender = _routesInLimbo[id];
        _mint(sender, tokenId);
        _routeData[tokenId] = RouteData(num1 % 100, RouteType(num2 % uint32(type(RouteType).max)), AircraftType(num3 % uint32(type(AircraftType).max)));
        _tokenIdTracker.increment();
        // I think? a fail to burn will cause reversion even if we fail to burn cause out of gas (we aren't using call)
        // Idk I should look up exact behavior though to be sure
        _aero.burnFrom(sender, 100);
        emit routeAdded(tokenId);
    }
}