# ALTAVA-staking-contract

Altava staking protocol is to distribute third-party ERC20 reward tokens to TAVA token stakers. <br />
TAVA token holders can participate in staking and can get benefit by receiving third-party tokens and third-party NFT tokens. <br />
Altava staking is locked staking and users cannot unlock staked tokens before the unlock date. <br />
Some reward tokens would be claimed directly by the user and some reward tokens would be airdropped by admin when the locking period ends, because reward token might comes from other chains.

## Install

Make sure you have already set up and installed <br /> `npm` and `yarn`.
Download project on local, and run <br /> `yarn install`

### Compile

Before compile project, you need to add two \*.sol files. They are ERC20 token and ERC721 token contract files, which would be your tokens.
Please named them "TAVA.sol" and "SecondskinNFT.sol".
To compile smart contract codes on local, run following command line. <br />
`yarn compile` or `yarn build`

### Coverage

To get solidity coverage with unit tests, please run following command line. <br />
`yarn coverage`

### GasUsed

To get gas used overview, please run following command line. <br />
`yarn profile`

### Unit tests

To run unit testing, please run following command line <br />
`yarn test`

## Deploy

### Env

First create .env file by copying .env.example. <br />
`DEPLOYER_KEY` is your wallet private key. <br />
You can get `ALCHEMY_API_KEY` from [here](https://www.alchemy.com/). <br />
`ETHERSCAN_API_KEY` This would be used for verifying contract on etherscan. <br />
`CMC_API_KEY` This would be used for `gasUsed`. <br />

### Deploy (testnet)

You can deploy your contract on any testnet as you want.<br />
`yarn deploy:<NETWORK_NAME>`<br />
You can find `<NETWORK_NAME>` in hardhat.config.js file.<br />

### Deploy (mainnet)

You can deploy your contract on any testnet as you want.<br />
`yarn deploy:mainnet`

## Testnet (bsc testnet) Nov 24th

### TAVA Contract

[`0x5Bd94A8Be93F2F9e918B8C08104962Bcd22a9B2D`](https://testnet.bscscan.com/address/0x5Bd94A8Be93F2F9e918B8C08104962Bcd22a9B2D)

### SecondSkinNFT Contract

[`0x03222f6Ee842c079b3d88e7abDb362193FC5BE26`](https://testnet.bscscan.com/address/0x03222f6Ee842c079b3d88e7abDb362193FC5BE26)

### BoosterController Contract

[`0xCe91708D3749F9d544166dEFaBC0638F2Ad06182`](https://testnet.bscscan.com/address/0xCe91708D3749F9d544166dEFaBC0638F2Ad06182)

### NFTStaking Contract

[`0x4F97ec81bdB27FcEA53614161EC29715c8FB15cb`](https://testnet.bscscan.com/address/0x4F97ec81bdB27FcEA53614161EC29715c8FB15cb)

### NFTMasterChef

[`0xCA052C2c5CA7cF81C5D47CA6F1dCD5803D491365`](https://testnet.bscscan.com/address/0xCA052C2c5CA7cF81C5D47CA6F1dCD5803D491365)

### MasterChef

[`0xbFF85397C9A0d1eA4Daa6DD6CcD2b4c59A009842`](https://testnet.bscscan.com/address/0xbFF85397C9A0d1eA4Daa6DD6CcD2b4c59A009842)

### Token Generate Factory

[`0x4f062510762A86E59941b87cc4fad955e6867814`](https://testnet.bscscan.com/address/0x4f062510762A86E59941b87cc4fad955e6867814)

### NFT Generate Factory

[`0xab9BEE265A4A00714f6A63A7bD846569BC68fD0C`](https://testnet.bscscan.com/address/0xab9BEE265A4A00714f6A63A7bD846569BC68fD0C)
