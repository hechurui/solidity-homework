const { ethers, upgrades } = require("hardhat");

//部署合约
//npx hardhat run scripts/test1.js --network sepolia
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("部署人:", deployer.address);

  // 部署NftAuction合约到ETH
  const NftAuction = await ethers.getContractFactory("NFT");

  // 部署代理合约，并且申明uups
  const nftAuction = await upgrades.deployProxy(NftAuction, [deployer.address], { kind: "uups" });

  // 等待代理合约部署完成
  await nftAuction.waitForDeployment();

  // 获取代理合约地址AUCTION_ADDRESS
  const proxyAddress = await nftAuction.getAddress();

  console.log("NftAuction deployed to (proxy):", proxyAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});