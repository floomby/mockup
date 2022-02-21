#!/bin/bash

rm -f compiled.js

# 10 out of 10 on consistent naming...
printf "exports.aero_abi = JSON.parse(" >> compiled.js
solc --abi aero/Aero.sol | sed -n '/aero\/Aero.sol:Aero /{n;n;p}' | sed -z '$ s/\n$//' >> compiled.js
printf ");\nexports.aero_bin = \"0x" >> compiled.js
solc --bin aero/Aero.sol | sed -n '/aero\/Aero.sol:Aero /{n;n;p}' | sed -z '$ s/\n$//' >> compiled.js
printf "\";\n\n" >> compiled.js

printf "exports.route_abi = JSON.parse(" >> compiled.js
solc --abi routes/Routes.sol | sed -n '/routes\/Routes.sol:Route /{n;n;p}' | sed -z '$ s/\n$//' >> compiled.js
printf ");\nexports.route_bin = \"0x" >> compiled.js
solc --bin routes/Routes.sol | sed -n '/routes\/Routes.sol:Route /{n;n;p}' | sed -z '$ s/\n$//' >> compiled.js
printf "\";\n\n" >> compiled.js

printf "exports.airport_abi = JSON.parse(" >> compiled.js
solc --abi airports/Airport.sol | sed -n '/airports\/Airport.sol:Airport /{n;n;p}' | sed -z '$ s/\n$//' >> compiled.js
printf ");\nexports.airport_bin = \"0x" >> compiled.js
solc --bin airports/Airport.sol | sed -n '/airports\/Airport.sol:Airport /{n;n;p}' | sed -z '$ s/\n$//' >> compiled.js
printf "\";\n" >> compiled.js