#!/bin/bash

rm -f compiled.js

# 10 out of 10 on consistent naming...
printf "export default {\n" >> compiled.js

printf "    aero_abi: " >> compiled.js
solc --abi aero/Aero.sol | sed -n '/aero\/Aero.sol:Aero /{n;n;p}' | sed -z '$ s/\n$//' >> compiled.js
printf ",\n    aero_bin: \"0x" >> compiled.js
solc --bin aero/Aero.sol | sed -n '/aero\/Aero.sol:Aero /{n;n;p}' | sed -z '$ s/\n$//' >> compiled.js
printf "\",\n" >> compiled.js

printf "    route_abi: " >> compiled.js
solc --abi routes/Routes.sol | sed -n '/routes\/Routes.sol:Route /{n;n;p}' | sed -z '$ s/\n$//' >> compiled.js
printf ",\n    route_bin: \"0x" >> compiled.js
solc --bin routes/Routes.sol | sed -n '/routes\/Routes.sol:Route /{n;n;p}' | sed -z '$ s/\n$//' >> compiled.js
printf "\",\n" >> compiled.js

printf "    airport_abi: " >> compiled.js
solc --abi airports/Airport.sol | sed -n '/airports\/Airport.sol:Airport /{n;n;p}' | sed -z '$ s/\n$//' >> compiled.js
printf ",\n    airport_bin: \"0x" >> compiled.js
solc --bin airports/Airport.sol | sed -n '/airports\/Airport.sol:Airport /{n;n;p}' | sed -z '$ s/\n$//' >> compiled.js
printf "\",\n" >> compiled.js

printf "    ioraclinatorable_abi: " >> compiled.js
solc --abi oraclinator/IOraclinatorable.sol | sed -n '/oraclinator\/IOraclinatorable.sol:IOraclinatorable /{n;n;p}' | sed -z '$ s/\n$//' >> compiled.js
printf ",\n    oraclinator_abi: " >> compiled.js
solc --abi oraclinator/Oraclinator.sol | sed -n '/oraclinator\/Oraclinator.sol:Oraclinator /{n;n;p}' | sed -z '$ s/\n$//' >> compiled.js
printf ",\n    oraclinator_bin: \"0x" >> compiled.js
solc --bin oraclinator/Oraclinator.sol | sed -n '/oraclinator\/Oraclinator.sol:Oraclinator /{n;n;p}' | sed -z '$ s/\n$//' >> compiled.js
printf "\"\n}\n" >> compiled.js