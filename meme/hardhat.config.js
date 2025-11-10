require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("@dotenvx/dotenvx").config();
require("solidity-coverage"); 
require("hardhat-gas-reporter");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  namedAccounts: {
    deployer: 0,
    user1: 1,
    user2: 2,
    user3: 3,
  },
  coverage: {
    // 在这里设置报告类型
    reporters: [
      "html",  // 生成HTML报告
      "lcov",  // 生成LCOV报告（用于Coveralls）
      "text",  // 在终端显示文本报告
      "json"   // 生成JSON报告
    ]
  },
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      allowUnlimitedContractSize: true,
    },
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.SEPOLIA_URL_KEY}`,
      accounts: [process.env.SEPOLIA_ACCOUNTS_KEY,process.env.SEPOLIA_ACCOUNTS_KEY2],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  sourcify: {
    enabled: true,
  },
};