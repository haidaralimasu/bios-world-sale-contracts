import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-abi-exporter";
import dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10_000,
      },
    },
  },
  networks: {
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: [process.env.WALLET_PRIVATE_KEY!].filter(Boolean),
    },
    sepolia: {
      url: "https://sepolia.infura.io/v3/d014af161a4b4ffbaa358366e232e2c8",
      accounts: process.env.MNEMONIC
        ? { mnemonic: process.env.MNEMONIC }
        : [process.env.WALLET_PRIVATE_KEY!].filter(Boolean),
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org/",
      accounts: process.env.MNEMONIC
        ? { mnemonic: process.env.MNEMONIC }
        : [process.env.WALLET_PRIVATE_KEY!].filter(Boolean),
    },
    bsc_test: {
      url: "https://data-seed-prebsc-2-s1.binance.org:8545/",
      accounts: process.env.MNEMONIC
        ? { mnemonic: process.env.MNEMONIC }
        : [process.env.WALLET_PRIVATE_KEY!].filter(Boolean),
    },
    hardhat: {
      initialBaseFeePerGas: 0,
      forking: {
        url: "https://data-seed-prebsc-2-s1.binance.org:8545/",
      },
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  typechain: {
    outDir: "./typechain",
  },
  abiExporter: {
    path: "./abis",
    only: [
      "HangingTrailsToken",
      "HangingTrailsSaleBSC",
      "HangingTrailsSaleETH",
    ],
  },
  gasReporter: {
    enabled: !process.env.CI,
    currency: "USD",
    gasPrice: 50,
    src: "contracts",
    coinmarketcap: "7643dfc7-a58f-46af-8314-2db32bdd18ba",
  },
  // mocha: {
  //   timeout: 60_000,
  // },
};

export default config;
