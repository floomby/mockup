// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721PresetMinterPauserAutoId.sol";
import "../Counters.sol";

import "../aero/Aero.sol";

contract Airport is ERC721PresetMinterPauserAutoId, CheckAero {
    Aero private _aero;

    using Counters for Counters.Counter;
    address private _aeroContractAddress;

    // Just make this super simple for now (in reality you could have have many attributes which are
    // all upgrade/downgradeable which could be added after contract deployment)
    uint256 constant _runwayPrice = 100;
    mapping(uint256 => uint16) private _runways;

    constructor(string memory baseURI, address aeroContractAddress) ERC721PresetMinterPauserAutoId("Airport nft", "ARPRT", baseURI) {
        _aero = Aero(aeroContractAddress);
        require(isAeroContract(_aero), "Must provide a valid aero contract");
    }

    function runwayCount(uint256 tokenId) public view returns (uint16) {
        require(_exists(tokenId), "Runway query for nonexistent token");
        return _runways[tokenId];
    }

    function mint(address to) public override virtual {
        uint256 tokenId = _tokenIdTracker.current();
        super.mint(to);
        _runways[tokenId] += 1;
    }

    function addRunway(uint256 tokenId) public {
        require(_exists(tokenId), "Runway addition for nonexistent token");
        require(_runways[tokenId] != type(uint16).max, "Already at max runways");
        _runways[tokenId] += 1;
        _aero.burnFrom(_msgSender(), _runwayPrice);
    }
}
