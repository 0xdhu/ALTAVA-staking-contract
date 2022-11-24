
# NFTStaking
npx hardhat verify --contract contracts/NFTStaking.sol:NFTStaking --network testnet 0xaA34DdC70Af714B030C7565dBD11F5874385B8E6 "0x03222f6Ee842c079b3d88e7abDb362193FC5BE26"

# BoosterController
npx hardhat verify --contract contracts/BoosterController.sol:BoosterController --network testnet 0xEDfC8C081fbA2500397A6522E066F332c0eB6C02

# MasterChef (locked staking)
npx hardhat verify --contract contracts/MasterChef.sol:MasterChef --network testnet 0x0eFD10E89b1D64c206674cF666fcE1B967e9D779 "0xaA34DdC70Af714B030C7565dBD11F5874385B8E6"

# NFTMasterChef (tava, locked staking)
npx hardhat verify --contract contracts/NFTMasterChef.sol:NFTMasterChef --network testnet 0x17fDB389942e12956B527596b3E7b70c485960Bd "0x5Bd94A8Be93F2F9e918B8C08104962Bcd22a9B2D" "0xaA34DdC70Af714B030C7565dBD11F5874385B8E6"