![Algem Logo](LiquidStakingV1_5/logo.svg)

Algem is a decentralized protocol developed to enhance staking and farming opportunities within the blockchain ecosystem. This repository contains two primary subprojects: **LiquidStakingV2** and **LiquidFarming**, each designed to provide innovative solutions for liquidity providers, stakers, and farmers. Built with modularity and scalability in mind, Algem leverages smart contracts to integrate with various decentralized applications (dApps) and networks.

## Subprojects

### LiquidStakingV2

**LiquidStakingV2** is the next evolution of the LiquidStaking protocol on the Astar network, allowing users to stake native ASTR tokens and receive **xnASTR**, a liquid, reward-bearing token. This token can be utilized in other protocols to generate additional profits while maintaining flexibility. Key features include:

- **Reward-Bearing Mechanism**: The value of xnASTR adjusts based on the ratio of total xnASTR supply to ASTR locked in the contract, reflecting accumulated rewards.
- **Cross-Chain Interoperability**: Implements the Cross-Chain Interoperability Protocol (CCIP) for seamless token transfers across networks.
- **Voting System**: Introduces a dApp voting mechanism using **veALGM** tokens, where higher votes allocate more staking power to specific dApps.
- **Cashback Rewards**: Users can lock ALGM tokens and Algem NFTs to claim additional ASTR rewards, enhancing staking incentives.
- **Structure**: Comprises multiple contracts, including `LiquidStaking` (diamond structure), `LiquidStakingMain` (core logic), `LiquidStakingVoting` (voting functions), and `XNASTR` (ERC20 token), among others.

This subproject is tailored for users seeking flexible staking options with added governance and reward opportunities, with deployment planned for both Astar and Soneium networks.

### LiquidFarming

**LiquidFarming** is a sophisticated protocol designed to aggregate farming rewards from various dApps (e.g., DEXes like Uniswap, PancakeSwap) while offering additional incentives through **ALGM** token staking. Users provide liquidity (ETH + ERC20 pairs) to participate in farming rounds, with rewards distributed based on ALGM stakes. Key aspects include:

- **Core Idea**: Users deposit liquidity to mint **LWRAPPED** tokens (pegged 1:1 to Ether), farm rewards across rounds, and increase their ALGM stake value, culminating in exclusive final-round rewards for ALGM stakers.
- **LWRAPPED Tokens**: Minted on deposit, these tokens can be redeemed for Ether via `redeem()` (if the user holds a position) or `withdraw()` (post-vault expiration).
- **Protocol Structure**: 
  - **Protocol-Wide Contracts**: `LFMaster` (root contract per chain) manages ALGM distribution and pool setup, while `LWRAPPEDCentre` aids in vault withdrawals.
  - **dApp-Specific Contracts**: Each supported dApp (e.g., UniswapV3, Algebra) has tailored implementations under `dApps/%DAPP_NAME%`, handling liquidity provision, reward collection, and ALGM distribution.
- **Vault and Pool System**: Up to three vaults per pool manage finite lifetimes, reward claims, and liquidations, while pools aggregate liquidity and distribute ALGM incentives.
- **Flexibility**: Supports an extensible list of dApps with configurable addresses (e.g., WETH, pair tokens, V3 pools).

This subproject caters to liquidity providers aiming to maximize farming yields with a blend of native and ALGM-based rewards.

## Project Details

- **Development Tools**: Built using Foundry (`forge`), with recommended flags `--force` and `--ffi` for compilation and upgrades.
- **Testing**: Supports testing with forks (e.g., Soneium RPC) to simulate real-world conditions.
- **Scripts**: Deployment and upgrade scripts are provided for both subprojects, facilitating pool/vault setup and configuration management via keystores.

Algem aims to bridge staking and farming functionalities, offering users a robust platform to engage with DeFi ecosystems while maintaining control over their assets. Explore the subdirectories for detailed contract implementations and deployment instructions.