/** @type import('hardhat/config').HardhatUserConfig */
require('dotenv').config()
require("@nomicfoundation/hardhat-toolbox");

// Go to https://www.alchemyapi.io, sign up, create
// a new App in its dashboard, and replace "KEY" with its key
const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;

// Replace this private key with your Goerli account private key
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key
// Beware: NEVER put real Ether into testing accounts
const PRIVATE_KEY = process.env.PRIVATE_KEY;

// Verify contract
// const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

const DEPLOYER_KEY = process.env.DEPLOYER_KEY;

// Verify contract
const BSCSCAN_API_KEY = process.env.BSCSCAN_API_KEY;

module.exports = {
  solidity: "0.8.17",
  settings: { optimizer: { enabled: true, runs: 20 } },
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [PRIVATE_KEY]
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/`,
      accounts: [PRIVATE_KEY]
    },
    // Bsc testnet
    testnet: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
      accounts: [DEPLOYER_KEY]
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: BSCSCAN_API_KEY
  }
};
