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

[`0x9d7A56260516fEd6eBd255F0d82C483BC3D9DC3B`](https://testnet.bscscan.com/address/0x9d7A56260516fEd6eBd255F0d82C483BC3D9DC3B)

### SecondSkinNFT Contract

[`0x322baa6c6290D48a0b64139997aa7E4247A2d40F`](https://testnet.bscscan.com/address/0x322baa6c6290D48a0b64139997aa7E4247A2d40F)

### BoosterController Contract

[`0xe8643dFaA341e428341111d642fC54A956daAE70`](https://testnet.bscscan.com/address/0xe8643dFaA341e428341111d642fC54A956daAE70)

### NFTStaking Contract

[`0x70738BA5b782c1417D5A5A17cC32E8984ded0e4B`](https://testnet.bscscan.com/address/0x70738BA5b782c1417D5A5A17cC32E8984ded0e4B)

### NFTMasterChef

[`0x2409379591922072ffCd097D0f8d6A52e93ab9dE`](https://testnet.bscscan.com/address/0x2409379591922072ffCd097D0f8d6A52e93ab9dE)

### MasterChef

[`0x39931aDF1De4d068A5747e4c5d7B81f9CfADCfbE`](https://testnet.bscscan.com/address/0x39931aDF1De4d068A5747e4c5d7B81f9CfADCfbE)

### Token Generate Factory

[`0x825dDD8018B3EafD7ddf53Ef34c722a8c5cDfa04`](https://testnet.bscscan.com/address/0x825dDD8018B3EafD7ddf53Ef34c722a8c5cDfa04)

### NFT Generate Factory

[`0xA366E17261833E3BBD8f89D25F8D6f9c24DF10f9`](https://testnet.bscscan.com/address/0xA366E17261833E3BBD8f89D25F8D6f9c24DF10f9)
