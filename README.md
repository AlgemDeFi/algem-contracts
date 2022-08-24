![Algem Logo](https://github.com/DippyArtu/algem/blob/main/pics/logo-alpha.png?raw=true)

# Install
**Commands executed from the home directory**

Clone the source code, install dependencies.

```git clone https://github.com/AlgemDeFi/algem-contracts```

```$cd ~/algem-contracts```

```$npm install```

# Astar local chain

Get latest astar-collator [binary](https://github.com/AstarNetwork/Astar/releases)

To start dev node run
```./astar-collator --dev```

### Check out helper tasks!
Run ```npx hardhat %TASK_NAME%```
* *convertAddr* convert evm address to polkadot
* *giveMoney* give native tokens from //Alice dev account
* *registerDapp* register contract in DAPPS_STAKING module

# Compile

```$npx hardhat compile```

# Deploy

```npx hardhat run scripts/init.ts```

# Post-deploy routine
```npx hardhat run scripts/init.ts```

# Test

```npx hardhat test --network astarLocal```

