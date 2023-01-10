
# NFTStaking
npx hardhat verify --contract contracts/NFTStaking.sol:NFTStaking --network goerli 0xF4A19118c8Df7980755833bd022e06D73DCE55df "0x421Df1dc29Da5666838659Cd4915dD248150Ef18"

# BoosterController
npx hardhat verify --contract contracts/BoosterController.sol:BoosterController --network goerli 0xB3b204fdb42638716BcCc8c9EFfCE6Fa2999E6E3

# MasterChef (locked staking)
npx hardhat verify --contract contracts/MasterChef.sol:MasterChef --network goerli 0xC3dF3377E4354acc73e09b21A7AbAa458AB6D4F5 "0xF4A19118c8Df7980755833bd022e06D73DCE55df"

# NFTMasterChef (tava, locked staking)
npx hardhat verify --contract contracts/NFTMasterChef.sol:NFTMasterChef --network goerli 0x472576D4ee21122e95640c2f5955e0221d168aD8 "0xFC18C9D110deFb4d03bbBBc43f3AD5f5dC7Be178" "0xF4A19118c8Df7980755833bd022e06D73DCE55df"

# npx hardhat verify --contract contracts/NFTChef.sol:NFTChef --network testnet 0x1120211facfcd87b4b92a8411a86c19954ffea8c
# npx hardhat verify --contract contracts/SmartChef.sol:SmartChef --network testnet 0x6a09834e99d971cf6b506942f7659c00eee338ec
# npx hardhat verify --contract contracts/ThirdPartyToken.sol:ThirdPartyToken --network goerli 0xE51F46FB4092dB5624e03dE79d43c1A81b2Fa054 "Reward Test Token" "RTT"
# npx hardhat verify --contract contracts/ThirdPartyNFT.sol:ThirdPartyNFT --network goerli 0x0Dc36Ad154c94C174F059fCf6FDE4f4706052D86 "0x26EF70978Cbc88D18DE8586A9CDa53ffEE6bD10F" "Bored Ape Golf Club" "BAGC"
npx hardhat verify --contract contracts/TokenFactory.sol:TokenFactory --network goerli 0x9bBab5E416a5899b0aA7D62c1b1800fa9fFd77a5
npx hardhat verify --contract contracts/NFTFactory.sol:NFTFactory --network goerli 0x821fDe8CAa276490fD249e00cb25e252FFB8E503

npx hardhat verify --contract contracts/SendOBT.sol:SendOBT --network goerli 0x4eEEF14818A6D50688Ab54bec77Fee3B33cae72a
npx hardhat verify --contract contracts/TAVA.sol:TAVA --network goerli 0xFC18C9D110deFb4d03bbBBc43f3AD5f5dC7Be178
npx hardhat verify --contract contracts/SecondSkinNFT.sol:SecondSkinNFT --network goerli 0x421Df1dc29Da5666838659Cd4915dD248150Ef18 "0x26EF70978Cbc88D18DE8586A9CDa53ffEE6bD10F"

# SecondSkinNFT:  https://goerli.etherscan.io/address/0x421Df1dc29Da5666838659Cd4915dD248150Ef18
# NFTStaking:  https://goerli.etherscan.io/address/0xF4A19118c8Df7980755833bd022e06D73DCE55df
# sendOBT Address:  https://goerli.etherscan.io/address/0x4eEEF14818A6D50688Ab54bec77Fee3B33cae72a