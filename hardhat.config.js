/** @type import('hardhat/config').HardhatUserConfig */
require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require("solidity-coverage");
require("hardhat-gas-reporter");

// Go to https://www.alchemyapi.io, sign up, create
// a new App in its dashboard, and replace "KEY" with its key
const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;

// Verify contract
// const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

const DEPLOYER_KEY = process.env.DEPLOYER_KEY;

// Verify contract
const BSCSCAN_API_KEY = process.env.BSCSCAN_API_KEY;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
const CMC_API_KEY = process.env.CMC_API_KEY;

module.exports = {
  solidity: "0.8.17",
  settings: { optimizer: { enabled: true, runs: 200 } },
  networks: {
    // Ethereum mainnet
    mainnet: {
      url: `https://mainnet.infura.io/v3/${ALCHEMY_API_KEY}`,
      accounts: [DEPLOYER_KEY],
    },
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [DEPLOYER_KEY],
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${ALCHEMY_API_KEY}`,
      accounts: [DEPLOYER_KEY],
    },
    // Bsc testnet
    testnet: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
      accounts: [DEPLOYER_KEY],
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: ETHERSCAN_API_KEY,
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    gasPrice: 11,
    currency: "USD",
    outputFile: "gasUsed.txt",
    noColors: true,
    coinmarketcap: CMC_API_KEY,
    excludeContracts: [
      "NFTFactory.sol",
      "SecondSkinNFT.sol",
      "TAVA.sol",
      "ThirdPartyNFT.sol",
      "ThirdPartyToken.sol",
      "TokenFactory.sol",
    ],
  },
  // specify separate cache for hardhat, since it could possibly conflict with foundry's
  paths: { cache: "hh-cache" },
};
