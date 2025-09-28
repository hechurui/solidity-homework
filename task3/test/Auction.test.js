const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("Auction", function () {
  let NFT;
  let nft;
  let Auction;
  let auction;
  let AuctionFactory;
  let auctionFactory;
  let ChainlinkPriceOracle;
  let priceOracle;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    // 获取签名者
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    // 部署NFT合约
    NFT = await ethers.getContractFactory("NFT");
    nft = await upgrades.deployProxy(NFT, ["TestNFT", "TNFT"]);
    await nft.deployed();

    // 部署价格预言机(测试用的模拟版本)
    ChainlinkPriceOracle = await ethers.getContractFactory("MockChainlinkPriceOracle");
    priceOracle = await ChainlinkPriceOracle.deploy();
    await priceOracle.deployed();
    await priceOracle.setPrice(ethers.constants.AddressZero, ethers.utils.parseEther("3000")); // ETH价格: 3000 USD

    // 部署拍卖实现合约
    Auction = await ethers.getContractFactory("Auction");
    const auctionImplementation = await Auction.deploy();
    await auctionImplementation.deployed();

    // 部署拍卖工厂
    AuctionFactory = await ethers.getContractFactory("AuctionFactory");
    auctionFactory = await upgrades.deployProxy(AuctionFactory, [
      auctionImplementation.address,
      priceOracle.address,
      ethers.constants.AddressZero // 测试中不使用真实的CCIP路由器
    ]);
    await auctionFactory.deployed();

    // 铸造NFT并授权给工厂
    await nft.mint(owner.address);
    await nft.approve(auctionFactory.address, 1);

    // 创建拍卖
    const startTime = Math.floor(Date.now() / 1000) + 60; // 1分钟后开始
    const endTime = startTime + 1800; // 持续30分钟
    const startPrice = ethers.utils.parseEther("0.1"); // 0.1 ETH

    await auctionFactory.createAuction(
      nft.address,
      1,
      ethers.constants.AddressZero, // ETH支付
      startTime,
      endTime,
      startPrice
    );

    // 获取创建的拍卖合约地址
    const auctions = await auctionFactory.getAllAuctions();
    auction = await ethers.getContractAt("Auction", auctions[0]);
  });

  describe("基本功能测试", function () {
    it("应该正确初始化拍卖信息", async function () {
      const info = await auction.getAuctionInfo();
      expect(info.seller).to.equal(owner.address);
      expect(info.nftContract).to.equal(nft.address);
      expect(info.tokenId).to.equal(1);
      expect(info.ended).to.equal(false);
    });

    it("应该允许用户出价", async function () {
      // 快进时间到拍卖开始
      await ethers.provider.send("evm_increaseTime", [60]);
      await ethers.provider.send("evm_mine");

      // 出价
      const bidAmount = ethers.utils.parseEther("0.2");
      await auction.connect(addr1).bid(bidAmount, { value: bidAmount });

      const info = await auction.getAuctionInfo();
      expect(info.highestBidder).to.equal(addr1.address);
      expect(info.highestBid).to.equal(bidAmount);
    });

    it("应该拒绝低于当前最高价的出价", async function () {
      // 快进时间到拍卖开始
      await ethers.provider.send("evm_increaseTime", [60]);
      await ethers.provider.send("evm_mine");

      // 第一次出价
      const firstBid = ethers.utils.parseEther("0.2");
      await auction.connect(addr1).bid(firstBid, { value: firstBid });

      // 尝试更低的出价
      const lowerBid = ethers.utils.parseEther("0.15");
      await expect(
        auction.connect(addr2).bid(lowerBid, { value: lowerBid })
      ).to.be.revertedWith("Bid not higher than current highest");
    });

    it("应该在拍卖结束后正确转移NFT和资金", async function () {
      // 快进时间到拍卖开始
      await ethers.provider.send("evm_increaseTime", [60]);
      await ethers.provider.send("evm_mine");

      // 出价
      const bidAmount = ethers.utils.parseEther("0.2");
      await auction.connect(addr1).bid(bidAmount, { value: bidAmount });

      // 快进时间到拍卖结束
      await ethers.provider.send("evm_increaseTime", [3600]);
      await ethers.provider.send("evm_mine");

      // 记录卖家余额
      const sellerBalanceBefore = await ethers.provider.getBalance(owner.address);

      // 结束拍卖
      await auction.endAuction();

      // 检查NFT所有权
      expect(await nft.ownerOf(1)).to.equal(addr1.address);

      // 检查卖家余额增加
      const sellerBalanceAfter = await ethers.provider.getBalance(owner.address);
      expect(sellerBalanceAfter).to.be.gt(sellerBalanceBefore);
    });
  });
});
