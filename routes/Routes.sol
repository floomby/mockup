// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../deps/Context.sol";
import "../deps/Strings.sol";

import "../airports/ERC721PresetMinterPauserAutoId.sol";
import "../aero/Aero.sol";

// Having this be a erc721 is overkill probably
contract Route is ERC721PresetMinterPauserAutoId, CheckAero {
    Aero private _aero;
    using Counters for Counters.Counter;
    mapping(uint256 => uint256) private _lengths;

    constructor(string memory baseURI, address aeroContractAddress) ERC721PresetMinterPauserAutoId("Routes", "RTS", baseURI) {
        _aero = Aero(aeroContractAddress);
        require(isAeroContract(_aero), "Must provide a valid aero contract");
    }

    function buyRoute() public {
        uint256 tokenId = _tokenIdTracker.current();
        _mint(_msgSender(), tokenId);
        // TODO somehow we need to set route properties (things like length, cargo vs commercial, etc. as well as figure the price out)
        // Some of this could have an element of randomness, maybe you don't quite know if how good the route is and you are trying to get lucky
        _lengths[tokenId] = 42;
        _tokenIdTracker.increment();
        _aero.burnFrom(_msgSender(), 100);
    }

    // We don't want routes to be minted like normal
    function mint(address to) public virtual override {
        revert();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "?length=", Strings.toString(_lengths[tokenId]))) : "";
    }
}