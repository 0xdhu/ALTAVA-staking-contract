
# NFTStaking
npx hardhat verify --contract contracts/NFTStaking.sol:NFTStaking --network testnet 0x0113765Ae30B859Cb2886b133E5b08194A2d412A "0x03222f6Ee842c079b3d88e7abDb362193FC5BE26"

# BoosterController
npx hardhat verify --contract contracts/BoosterController.sol:BoosterController --network testnet 0x14ff97Bcd0c019d9E46316Ef2ee3CDa035572833

# MasterChef (locked staking)
npx hardhat verify --contract contracts/MasterChef.sol:MasterChef --network testnet 0xF451A0C6Ec26f952Db6361468443eadF6CdbdE15 "0x0113765Ae30B859Cb2886b133E5b08194A2d412A"

# NFTMasterChef (tava, locked staking)
npx hardhat verify --contract contracts/NFTMasterChef.sol:NFTMasterChef --network testnet 0xDeadd1886C1fa2A376d847B3234Bb459284F1aCA "0x5Bd94A8Be93F2F9e918B8C08104962Bcd22a9B2D" "0x0113765Ae30B859Cb2886b133E5b08194A2d412A"

# npx hardhat verify --contract contracts/NFTChef.sol:NFTChef --network testnet 0x1120211facfcd87b4b92a8411a86c19954ffea8c
# npx hardhat verify --contract contracts/SmartChef.sol:SmartChef --network testnet 0x6a09834e99d971cf6b506942f7659c00eee338ec