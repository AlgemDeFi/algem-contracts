#!/bin/bash

echo "Pulling stakers"
npx hardhat stakers --network shibuyaTestnet
echo "Shooting stakers"
npx hardhat shooter --network shibuyaTestnet
