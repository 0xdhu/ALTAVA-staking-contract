
# NFTStaking
npx hardhat verify --contract contracts/NFTStaking.sol:NFTStaking --network testnet 0x4F97ec81bdB27FcEA53614161EC29715c8FB15cb "0x03222f6Ee842c079b3d88e7abDb362193FC5BE26"

# BoosterController
npx hardhat verify --contract contracts/BoosterController.sol:BoosterController --network testnet 0xCe91708D3749F9d544166dEFaBC0638F2Ad06182

# MasterChef (locked staking)
npx hardhat verify --contract contracts/MasterChef.sol:MasterChef --network testnet 0xbFF85397C9A0d1eA4Daa6DD6CcD2b4c59A009842 "0x4F97ec81bdB27FcEA53614161EC29715c8FB15cb"

# NFTMasterChef (tava, locked staking)
npx hardhat verify --contract contracts/NFTMasterChef.sol:NFTMasterChef --network testnet 0xCA052C2c5CA7cF81C5D47CA6F1dCD5803D491365 "0x5Bd94A8Be93F2F9e918B8C08104962Bcd22a9B2D" "0x4F97ec81bdB27FcEA53614161EC29715c8FB15cb"