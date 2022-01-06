import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const ALCHEMY_API_KEY = "LM5D_zRIpEi2cc8x1NfMZxarelM_mMzI";
const PRIVATE_KEY1 = "276df57441f69924ad3481a16d49816f74a0796f89df5caa232e2c1db9621133";
const PRIVATE_KEY2 = "65115315358bd2fba2e6af46444f99e38cabfdd5120056d89ec38b1dbb9b2737";
const PRIVATE_KEY3 = "22cced1c05d46c29237517b149c8e647390fc853574978392693e5fe5653fc2b";

const config: HardhatUserConfig = {
  solidity: "0.8.11",
  networks: {
    ropsten: {
      url: process.env.ROPSTEN_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [`${PRIVATE_KEY1}`,`${PRIVATE_KEY2}`,`${PRIVATE_KEY3}`],
      gasPrice: 3000000000,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
