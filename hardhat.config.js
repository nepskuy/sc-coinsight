require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY || "0000000000000000000000000000000000000000000000000000000000000000";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY || "";
const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY || "";
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY || "";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: {
        version: "0.8.23",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
            viaIR: false,
        },
    },

    networks: {
        hardhat: {
            chainId: 31337,
            allowUnlimitedContractSize: true,
        },
        localhost: {
            url: "http://127.0.0.1:8545",
            chainId: 31337,
        },
        sepolia: {
            url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
            accounts: [PRIVATE_KEY],
            chainId: 11155111,
        },
        polygonMumbai: {
            url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
            accounts: [PRIVATE_KEY],
            chainId: 80001,
        },
        baseSepolia: {
            url: "https://sepolia.base.org",
            accounts: [PRIVATE_KEY],
            chainId: 84532,
        },
        arbitrumSepolia: {
            url: "https://sepolia-rollup.arbitrum.io/rpc",
            accounts: [PRIVATE_KEY],
            chainId: 421614,
        },
    },

    etherscan: {
        apiKey: {
            sepolia: ETHERSCAN_API_KEY,
            polygonMumbai: POLYGONSCAN_API_KEY,
            baseSepolia: ETHERSCAN_API_KEY,
            arbitrumSepolia: ETHERSCAN_API_KEY,
        },
    },

    gasReporter: {
        enabled: process.env.REPORT_GAS === "true",
        currency: "USD",
        coinmarketcap: COINMARKETCAP_API_KEY,
        outputFile: "gas-report.txt",
        noColors: true,
    },

    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts",
    },

    mocha: {
        timeout: 40000,
    },
};
