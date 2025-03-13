# LiquidFarming protocol
## Idea
The protocol is used for accumulating farming rewards of various dApps (DEXes) with additional ALGM token incentives. User has to provide ETH+ERC20 liquidity in order to start farming. Then, each round user can claim rewards and un/re-stake ALGM. During the vault lifetime, ALGM stake amount becomes more valuable in terms of farming rewards distribution when finally, last round farming rewards are distributed ONLY between ALGM stakers. Upon deposit, there is also a certain amount of LWRAPPED tokens minted. LWRAPPED token price is 1:1 native token (Ether in case of Ethereum chain) and it can be unwrapped back with redeem() if LWRAPPED holder has a position or using withdraw() after the vault has expired.
## Structure
Liquid Farming is a complex project with lots of moving parts. It was decided to keep project-wide contracts at the root of the ```src``` while dApp-specific code is separated in ```dApps/%DAPP_NAME%``` folders. The reasoning behind this is the amount of small differences among other dApps like UniswapV3SwapCallback/PancakeV3SwapCallback/AlgebraSwapCallback. It is crucial to keep track of those nuances but additional attention required with global updates.
### Naming
Basically, any contract under ```src``` starting with **L** in name is a final contract (LFMaster, LWRAPPED, LWRAPPEDCentre, dApps/.../LFx...V3...). Take a note, there are also ```src/Vault.sol, src/Pool.sol``` which are abstract contracts with protocol-wide functionality used by ```LFMaster``` and ```LWRAPPEDCentre```.
### Protocol-wide
These are the contracts that are used to aggregate info on the available pools and vaults with front-end related getters. Also this is a starting point for ALGM distribution. 
#### LFMaster
**1 contract per chain**, basically the root of the protocol.
* Set duration and starting timestamp. Each round ALGM distribution can be triggered.
* Add LF pools with provided dApp name, pair name, and round deadline. Provide ALGM for added pool. From now on until the deadline, pool can call harvest() function each round to receive a portion of issued ALGM.
* User can lock 1 NFT to get additional ALGM APR bonus. There should be elegible NFT somewhere which address is being set with bonus amount. For simplicity, any NFT can be locked, but only "registered" ones has a bonus.
* User can generate a refcode and become a referrer or use one's refcode and become a referral. Obviously, you can become a referrer and referral only once.
#### LWRAPPEDCentre
**1 contract per chain**, helper contract for any LWRAPPED holder to quickly find the vault to ```withdraw()```
* Each vault and its LWRAPPED token has to be registered in order to be used.
### dApp-specific
The fun part starts here. Basically, there may be any amount of dApps supported. For each dApp, there is a list of required addresses:
| Contract name           | Address                                    |
|-------------------------|--------------------------------------------|
| **WETH**                | WETH token used by the dApp                |
| **PAIR**                | ERC20pair token(s)                         |
| **PAIR WHALE**          | ERC20pair holder to use in tests (optional)|
| **V3 Pool**             | liquidity pool to work with                |
#### Pool
**1 per liquidity pool**, this contract is used to aggregate info on liquidity provided and distribute ALGM between vaults.
* (Possibly) infinite lifetime.
* Receives ALGM from LFMaster and distributes further to the vaults.
* Up to 3 active vaults.
* Vault should be registered with a share > 0 in order to receive ALGM incentives.
#### LWRAPPED
**1 per vault**, 1:1 ether, this token is minted upon deposit and can be burned on ```vault.redeem()``` or ```vault.withdraw()```
* simple owner-protected mint/burn
* transfer ownership to vault
#### Vault
**up to 3 per pool**, this contract receives user liquidity, provides it to the dApp, collects and distributes rewards.
* Finite lifetime. Vault START timestamp should respect the LFMaster timestamp e.g. ```vault.START == LFMaster.START + LFMaster.round * n```. After vault has started, it should collect farming and ALGM rewards and distribute them between users.
* Deposits can be made from ```START``` until ```FINISH - 1 round```. Deposit amounts are determined by ```Vault.getInputAmounts()```. On deposit, LWRAPPED tokens are minted to the user: deposited liquidity price converted to ETH and divided by 2. Initial round depositers can get their rewards next round, others have to wait 1 full round to start receiving rewards.
* Redeem can be made at any point in time. If the vault is still active, user ALGM is unstaked, LP share is withdrawn, unwrapped and transferred to the user. If the vault is active, but user has been liquidated, the amount of liquidity received is determined on ```liquidate()``` call. If the vault has expired, user receives his share of already withdrawn and unwrapped liquidity. The amount of ETH received is also affected by the amount of LWRAPPED tokens holded. E.g. if user has no LWRAPPED at all, he will receive only ERC20 pair token, if there are more LWRAPPED than needed, only initially minted LWRAPPED amount would be burned.
* Claim can be called each round, with additional restake option. User will always receive his share of farming rewards upon this call. Also if ```restake==true```, all ALGM rewards would be restaked back to the vault to receive additional farming rewards next round.
* Unstake ALGM can be done at any moment, as the name suggests, this decreases the user ALGM share.
* Withdraw allows any LWRAPPED holder to burn LWRAPPED and get equal amount of Ether. This is allowed only after the vault has expired.
* Liquidation may occur if the user health factor drops below a certain threshold. When this happens, user position can be liquidated, e.g. LP withdrawn, rewards claimed, ALGM unstaked. This is done in order to keep LWRAPPED supplied with ETH and prevent further losses.
#### Caller
V2/V3 caller is an abstract contract that encapsulates all the dApp-specific calls like adding/removing liquidity, price calculations etc.
## Project
It is recommended to use ```--force``` and ```--ffi``` with ```forge```. First one is needed dut to amount of contracts compiled at once, i believe. Anyways, you either can ```forge clean``` if you encounter abovementioned error, or just ```--force``` to force recompile. ```--ffi``` is needed to allow OZ-upgrades plugin to work properly.
### Install
```forge install```
### Configure
Account management is performed with the keystore. No .env private keys involved.
For quick reference, dApp addresses are saved to script/cfg. Here are some helpers to work with.
1. ```forge script script/Workbench.s.sol" --tc Workbench --sig "%FUNCTION_SIG%" --rpc-url https://rpc.minato.soneium.org/ --account %KEYSTORE_ACCOUNT_NAME% --ffi --force```
Available sigs:
* ```writeConfig()``` allows to easily add pair cfg located at ```scripts/cfg/CHAIN/dApps/DAPP/config.json```
* ```readConfigs()``` allows to quickly read all saved configs
### Test
```forge test --fork-url https://rpc.minato.soneium.org/ --ffi --force```
### Scripts
1. ```forge script script/dApps/%DAPP_NAME%/Deployer.s.sol --tc Deployer --sig "%FUNCTION_SIG%" --rpc-url https://rpc.minato.soneium.org/ --account %KEYSTORE_ACCOUNT_NAME% --ffi --force```
* ```deployVault()``` deploy vault without further setup
* ```deployPool()``` deploy pool without further setup
* ```addVault()``` deploy vault and perform required setup
* ```addPool()``` deploy pool and perform required setup
2. ```forge script script/dApps/%DAPP_NAME%/Upgrader.s.sol --tc Upgrader --sig "%FUNCTION_SIG%" --rpc-url https://rpc.minato.soneium.org/ --account %KEYSTORE_ACCOUNT_NAME% --ffi --force```
* ```upgradePool()``` upgrade pool proxy
* ```upgradeVault()``` upgrade vault proxy
