# ALTAVA-staking-contract

Altava staking protocol is to distribute third-party ERC20 reward tokens to TAVA token stakers.
TAVA token holders can participate in staking and can get benefit by receiving third-party tokens and third-party NFT tokens.
Altava staking is locked staking and users cannot unlock staked tokens before the unlock date.
Some reward tokens would be claimed directly by the user and some reward tokens would be airdropped by admin when the locking period ends, because reward token might comes from other chains.

## Install

Make sure you have already set up and installed `npm` and `yarn`.
Download project on local, and run `yarn install`

### Compile

Before compile project, you need to add two \*.sol files. They are ERC20 token and ERC721 token contract files, which would be your tokens.
Please named them "TAVA.sol" and "SecondskinNFT.sol".
To compile smart contract codes on local, run following command line.
`yarn compile` or `yarn build`

### Coverage

To get solidity coverage with unit tests, please run following command line.
`yarn coverage`

### GasUsed

To get gas used overview, please run following command line.
`yarn profile`

### Unit tests

To run unit testing, please run following command line
`yarn test`

## Deploy

### Env

First create .env file by copying .env.example.
`DEPLOYER_KEY` is your wallet private key.
You can get `ALCHEMY_API_KEY` from [here](https://www.alchemy.com/).
`ETHERSCAN_API_KEY` This would be used for verifying contract on etherscan.
`CMC_API_KEY` This would be used for `gasUsed`.

### Deploy (testnet)

You can deploy your contract on any testnet as you want.
`yarn deploy:<NETWORK_NAME>`
You can find `<NETWORK_NAME>` in hardhat.config.js file.

### Deploy (mainnet)

You can deploy your contract on any testnet as you want.
`yarn deploy:mainnet`

## Testnet (bsc testnet) Nov 24th

### TAVA Contract

[`0x5Bd94A8Be93F2F9e918B8C08104962Bcd22a9B2D`](https://testnet.bscscan.com/address/0x5Bd94A8Be93F2F9e918B8C08104962Bcd22a9B2D)

### SecondSkinNFT Contract

[`0x03222f6Ee842c079b3d88e7abDb362193FC5BE26`](https://testnet.bscscan.com/address/0x03222f6Ee842c079b3d88e7abDb362193FC5BE26)

### BoosterController Contract

[`0xEDfC8C081fbA2500397A6522E066F332c0eB6C02`](https://testnet.bscscan.com/address/0xEDfC8C081fbA2500397A6522E066F332c0eB6C02)

### NFTStaking Contract

[`0xaA34DdC70Af714B030C7565dBD11F5874385B8E6`](https://testnet.bscscan.com/address/0xaA34DdC70Af714B030C7565dBD11F5874385B8E6)

### NFTMasterChef

[`0x17fDB389942e12956B527596b3E7b70c485960Bd`](https://testnet.bscscan.com/address/0x17fDB389942e12956B527596b3E7b70c485960Bd)

### MasterChef

[`0x0eFD10E89b1D64c206674cF666fcE1B967e9D779`](https://testnet.bscscan.com/address/0x0eFD10E89b1D64c206674cF666fcE1B967e9D779)

### Token Generate Factory

[`0x4f062510762A86E59941b87cc4fad955e6867814`](https://testnet.bscscan.com/address/0x4f062510762A86E59941b87cc4fad955e6867814)

### NFT Generate Factory

[`0xab9BEE265A4A00714f6A63A7bD846569BC68fD0C`](https://testnet.bscscan.com/address/0xab9BEE265A4A00714f6A63A7bD846569BC68fD0C)
