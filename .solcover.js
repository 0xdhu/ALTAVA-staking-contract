module.exports = {
  skipFiles: [
    "TAVA.sol",
    "NFTFactory.sol",
    "SecondSkinNFT.sol",
    "ThirdPartyNFT.sol",
    "ThirdPartyToken.sol",
    "TokenFactory.sol",
  ],
  configureYulOptimizer: true,
  solcOptimizerDetails: {
    yul: true,
    yulDetails: {
      stackAllocation: true,
    },
  },
};
