
# NFTStaking
npx hardhat verify --contract contracts/NFTStaking.sol:NFTStaking --network goerli 0xb15a67F61d7250F5257A68e2D790AE03b913A59D "0x390708922E38E0e614574Ed9419a7103BAda5F6F"

# BoosterController
npx hardhat verify --contract contracts/BoosterController.sol:BoosterController --network goerli 0xe8643dFaA341e428341111d642fC54A956daAE70

# MasterChef (locked staking)
npx hardhat verify --contract contracts/MasterChef.sol:MasterChef --network goerli 0x39931aDF1De4d068A5747e4c5d7B81f9CfADCfbE "0xb15a67F61d7250F5257A68e2D790AE03b913A59D"

# NFTMasterChef (tava, locked staking)
npx hardhat verify --contract contracts/NFTMasterChef.sol:NFTMasterChef --network goerli 0x2409379591922072ffCd097D0f8d6A52e93ab9dE "0x9d7A56260516fEd6eBd255F0d82C483BC3D9DC3B" "0xb15a67F61d7250F5257A68e2D790AE03b913A59D"

# npx hardhat verify --contract contracts/NFTChef.sol:NFTChef --network testnet 0x1120211facfcd87b4b92a8411a86c19954ffea8c
# npx hardhat verify --contract contracts/SmartChef.sol:SmartChef --network testnet 0x6a09834e99d971cf6b506942f7659c00eee338ec
# npx hardhat verify --contract contracts/ThirdPartyToken.sol:ThirdPartyToken --network goerli 0xE8BfE3E070516E586f5cc5ceb21441093D506212 "AltavaStakingTestToken" "ASTT"
# npx hardhat verify --contract contracts/ThirdPartyNFT.sol:ThirdPartyNFT --network goerli 0xbEBcec5275E1adC8c46Cf6A730f7eC68fd67A199 "0xCED6A14D3955F3A0579D398Ac87140D6B7D5ad37" "AltavaStakingTestNFT" "ASTN"
# npx hardhat verify --contract contracts/TokenFactory.sol:TokenFactory --network goerli 0x825dDD8018B3EafD7ddf53Ef34c722a8c5cDfa04
# npx hardhat verify --contract contracts/NFTFactory.sol:NFTFactory --network goerli 0xA366E17261833E3BBD8f89D25F8D6f9c24DF10f9
# npx hardhat verify --contract contracts/SendOBT.sol:SendOBT --network goerli 0xceFd9f00cBC833eab9a687d4eCD4C7ac903EAA27
# npx hardhat verify --contract contracts/TAVA.sol:TAVA --network goerli 0x9d7A56260516fEd6eBd255F0d82C483BC3D9DC3B
# npx hardhat verify --contract contracts/SecondSkinNFT.sol:SecondSkinNFT --network goerli 0x390708922E38E0e614574Ed9419a7103BAda5F6F "0xCED6A14D3955F3A0579D398Ac87140D6B7D5ad37"

# SecondSkinNFT:  https://goerli.etherscan.io/address/0x390708922E38E0e614574Ed9419a7103BAda5F6F
# NFTStaking:  https://goerli.etherscan.io/address/0xb15a67F61d7250F5257A68e2D790AE03b913A59D
# sendOBT Address:  https://goerli.etherscan.io/address/0xceFd9f00cBC833eab9a687d4eCD4C7ac903EAA27