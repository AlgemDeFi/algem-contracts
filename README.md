![Algem Logo](https://github.com/DippyArtu/algem/blob/main/pics/logo-alpha.png?raw=true)

# Install
Clone the source code, install dependencies.

```git clone https://github.com/AlgemDeFi/algem-contracts```

```cd ~/algem-contracts```

```yarn install```

# Astar local chain
Get latest astar-collator [binary](https://github.com/AstarNetwork/Astar/releases)

To start dev node run
```yarn chain```
or
```./astar-collator --dev```

### Check out helper tasks!
Run ```npx hardhat %TASK_NAME%```
* **convertAddr** convert evm address to polkadot
* **giveMoney** give native tokens from //Alice dev account
* **registerDapp** register contract in DAPPS_STAKING module

# Compile
```yarn compile```
or
```npx hardhat compile```

# Deploy & setup
```yarn deploy --network %NETWORK_NAME%```
or
```npx hardhat run scripts/init.ts --network %NETWORK_NAME%```


# Test
```yarn test```
or
```npx hardhat test --network astarLocal```
