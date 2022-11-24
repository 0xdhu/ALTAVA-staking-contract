module.exports = {
  skipFiles: [
    "TAVA.sol",
    "NFTFactory.sol",
    "SecondSkinNFT.sol",
    "ThirdPartyNFT.sol",
    "ThirdPartyToken.sol",
    "TokenFactory.sol",
    "interfaces/IMasterChef.sol",
    "interfaces/INFTMasterChef.sol",
    "interfaces/INFTStaking.sol",
    "interfaces/IBoosterController.sol",
  ],
  configureYulOptimizer: true,
  solcOptimizerDetails: {
    yul: true,
    yulDetails: {
      stackAllocation: true,
    },
  },
};
