import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("dotenv").config({ path: ".env" });

const ALCHEMY_MAINNET_API_KEY_URL = process.env.ALCHEMY_MAINNET_API_KEY_URL;
const ALCHEMY_SEPOLIA_API_KEY_URL = process.env.ALCHEMY_SEPOLIA_API_KEY_URL;
const ALCHEMY_MUMBAI_API_KEY_URL = process.env.ALCHEMY_MUMBAI_API_KEY_URL;
const ACCOUNT= `0x${process.env.ACCOUNT}`

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    hardhat: {
      forking: {
        url: ALCHEMY_MAINNET_API_KEY_URL,
      }
    },
    sepolia: {
      url: ALCHEMY_SEPOLIA_API_KEY_URL,
      accounts: [ACCOUNT]
    },
    mumbai: {
      url: ALCHEMY_MUMBAI_API_KEY_URL!,
      accounts: [ACCOUNT],
    },
  }
};

export default config;
