import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
require('dotenv').config();

const public_rpc = 'https://ethereum-sepolia-rpc.publicnode.com';

const SEPOLIA_PRIVATE_KEY: string = String(process.env.Test_Secret);
const ETHERSCAN_APIKEY = process.env.Etherscan_Key;

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.20',
        settings: {
          optimizer: {
            enabled: true,
          },
        },
      },
      {
        version: '0.8.24',
        settings: {
          optimizer: {
            enabled: true,
          },
        },
      },
    ],
  },
  networks: {
    sepolia: {
      url: public_rpc,
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_APIKEY,
  },
  sourcify: {
    enabled: true,
  },
};

export default config;
