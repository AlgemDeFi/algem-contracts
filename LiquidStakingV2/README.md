
![Algem](https://github.com/azhlbn/LendingAdapter/blob/main/logo.png)

## Liquid Staking V2

LiquidStaking is a smart contract that allows staking native Astar network tokens to receive a liquid token, xnASTR, which can be used in other protocols to generate profits.

LiquidStaking V2 is the next generation of LiquidStaking V1.5. In V2, a new token, xnASTR, is used, which operates on the mechanics of rewards-bearing tokens. Control over accumulated rewards is achieved by changing the ratio of the total supply of xnASTR to ASTR locked in the contract.

xnASTR extends the Cross-Chain Interoperability Protocol (CCIP) standard for seamless token transfers across networks.

Additionally, LiquidStaking V2 introduces a voting system for dApps using veALGM tokens. The system works such that the more votes a dApp receives, the more tokens will be staked to that dApp.

The concept of cashback has also been added. By locking ALGM tokens and Algem protocol NFTs, users can claim an additional portion of the rewards in the form of ASTR tokens. These rewards can be claimed at any time.

### The structure

- `LiquidStaking` 
  The main contract of the diamond structure includes admin functions for global pause and contract manager assignment

- `LiquidStakingManager` 
  Responsible for routing calls to the main contract.

- `LiquidStakingMain` 
  The core logic of the contract is responsible for all aspects of staking and the distribution of the xnASTR token

- `LiquidStakingAdmin`
   Administrative logic for configuring all essential parameters

- `LiquidStakingVoting`
  Func related to voting

- `XNASTR` 
  Liquid token

- `LiquidStakingLayer2` 
  The contract that will be deployed on Soneium and will allow users to stake in DappsStaking Astar

## The main functionality

### LiquidStaking

- `pause` Global pause on entire functionality
- `unpause` Global unpause
- `setLiquidStakingManager` Sets address of manager contract
- `setPauseOnFunc` Sets certain function selector for partially pause
- `receive` (!) Need to be uncommented for tests but will be removed in production.

### LiquidStakingManager

- `addSelector` Add function selector for chosen address
- `addSelectorsBatch` Add batch of selectors
- `deleteSelector` 
- `changeSelector`
- `deleteAllAddressSelectors`

### LiquidStakingMain

- `stake` Add ASTR tokens and receive xnASTR instead in right proportion
- `unstake` Burn xnASTR tokens and sends ASTR tokens in case of immediate unstake or creates withdraw in case of regular unstake
- `withdraw` Allows to withdraw unlocked tokens, which previously were withdrawn from DappsStaking
- `addCashbackLock` Lock certain amount of xnASTR tokens and NFT or increase already locked amount
- `releaseCashbackLock` Unlock certain amount of xnASTR and NFT or decrease lock amount 
- `claimCashback` Claim accumulated cashback
- `sync` Allows to update state related to DappsStaking, withdraw unlocked tokens, claim accumulated rewards and initiate period if needed
- `getAccumulatedCashback` 
- `getXNASTRValue` Estimated number of xnASTR tokens relative to ASTR tokens
- `getASTRValue` Estimated number of ASTR tokens relative to xnASTR tokens

### LiquidStakingAdmin

- `restakeFromRewardPool` Certain amount of ASTR in rewardPool can be restaked to Dapps Staking
- `addNft` Add NFT for cashback locks
- `switchNftAvailability` Switch nft activity
- `withdrawBonusRewards` If there are any bonus rewards, function allows to withdraw it by manager
- `toggleWeights` Switch weights from vote weights to default weights or vice versa
- `withdrawRevenue` Allows to withdraw revenue for manager
- `changeDappAddress` In case of address of dapp was changed in Dapps Staking
- `partiallyPause` Disable chosen function
- `partiallyUnpause` 

### LiquidStakingVoting

- `addDapp` Add dapp to system
- `toggleDappAvailability` Switch dapp activity and recalculate weights
- `setDefaultWeights` Change default weights by manager

### XNASTR

ERC20 functionality. `mint` and `burn` functions available only for LiquidStaking contract.

### LiquidStakingLayer2

Since all calls from Soneium to Astar are made using ccip, there will be a delay in execution time.

- `stake` Send ASTR tokens and receive xnASTR instead in right proportion
- `unstake` Burn xnASTR tokens and sends ASTR tokens in case of immediate unstake or creates withdraw in case of regular unstake
- `withdraw` Allows to withdraw unlocked tokens, which previously were withdrawn from DappsStaking
- `vote` Allows to vote for dapp and increase weight of this dapp
- `unvote` Decrease weight of certain dapp