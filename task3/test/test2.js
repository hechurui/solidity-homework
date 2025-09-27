const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

const AUCTION_PROXY = process.env.AUCTION_ADDRESS;

//升级合约
// npx hardhat run scripts/test2.js --network sepolia
async function main() {
  console.log("开始升级...");

  const AuctionV2 = await ethers.getContractFactory("NFTV2");
  const upgraded = await upgrades.upgradeProxy(AUCTION_PROXY, AuctionV2);

  await upgraded.waitForDeployment();
  console.log("升级成功，地址 (proxy 不变):", await upgraded.getAddress());

  // 调用V2中function验证
  const msg = await upgraded.funcV2();
  console.log("V2 function 返回:", msg);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});