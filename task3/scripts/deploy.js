const { ethers, upgrades } = require("hardhat");

async function main() {
  // 部署NFT合约
  const NFT = await ethers.getContractFactory("NFT");
  const nft = await upgrades.deployProxy(NFT, ["AuctionNFT", "ANFT"]);
  await nft.deployed();
  console.log("NFT deployed to:", nft.address);

  // 部署Chainlink价格预言机
  // 注意：需要根据不同测试网配置正确的价格feed地址
  const priceFeeds = {
    // 以太坊主网的例子
    // eth: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419",
    // usdc: "0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576D4eE",
    
    // Sepolia测试网的例子
    eth: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
    usdc: "0x1d734A1DE1d624374a10a53Ee6411040D6D3E6A"
  };
  
  const ChainlinkPriceOracle = await ethers.getContractFactory("ChainlinkPriceOracle");
  const priceOracle = await ChainlinkPriceOracle.deploy(
    [ethers.constants.AddressZero, "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238"], // 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238是Sepolia上的USDC地址
    [priceFeeds.eth, priceFeeds.usdc]
  );
  await priceOracle.deployed();
  console.log("ChainlinkPriceOracle deployed to:", priceOracle.address);

  // 部署拍卖合约实现
  const Auction = await ethers.getContractFactory("Auction");
  const auctionImplementation = await Auction.deploy();
  await auctionImplementation.deployed();
  console.log("Auction implementation deployed to:", auctionImplementation.address);

  // 部署拍卖工厂合约
  const AuctionFactory = await ethers.getContractFactory("AuctionFactory");
  // Sepolia测试网的CCIP路由器地址
  const ccipRouter = "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59";
  
  const auctionFactory = await upgrades.deployProxy(AuctionFactory, [
    auctionImplementation.address,
    priceOracle.address,
    ccipRouter
  ]);
  await auctionFactory.deployed();
  console.log("AuctionFactory deployed to:", auctionFactory.address);

  console.log("Deployment completed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
