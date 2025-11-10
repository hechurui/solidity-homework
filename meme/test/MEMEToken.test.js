const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("MEMEToken", function () {
  // 部署合约的 fixture 函数
  async function deployMEMETokenFixture() {
    const [owner, taxReceiver, user1, user2] = await ethers.getSigners();
    
    const MEMEToken = await ethers.getContractFactory("MEMEToken");
    const memeToken = await MEMEToken.deploy();
    
    // 注意：可升级合约需要先调用 initialize()
    await memeToken.initialize();
    
    return { memeToken, owner, taxReceiver, user1, user2 };
  }

  describe("合约初始化", function () {
    it("应该正确设置代币名称和符号", async function () {
      const { memeToken } = await loadFixture(deployMEMETokenFixture);
      
      expect(await memeToken.name()).to.equal("MEME");
      expect(await memeToken.symbol()).to.equal("MM");
    });

    it("应该正确初始化供应量", async function () {
      const { memeToken, owner } = await loadFixture(deployMEMETokenFixture);
      
      const ownerBalance = await memeToken.balanceOf(owner.address);
      const contractBalance = await memeToken.balanceOf(memeToken.target);
      
      expect(ownerBalance).to.equal(ethers.parseEther("10000"));
      expect(contractBalance).to.equal(ethers.parseEther("10000"));
    });

    it("应该正确设置税务参数", async function () {
      const { memeToken, taxReceiver } = await loadFixture(deployMEMETokenFixture);
      
      expect(await memeToken._taxAddr()).to.equal("0x47391418DdD8A0D1FaD18f39DbC8eDF5b661C7C9");
      expect(await memeToken._taxRate()).to.equal(3);
      expect(await memeToken._minAmount()).to.equal(100);
      expect(await memeToken._maxAmount()).to.equal(ethers.parseEther("10"));
      expect(await memeToken._maxDailyTransactions()).to.equal(5);
    });
  });

  describe("参数配置功能", function () {
    it("只有所有者可以修改税务地址", async function () {
      const { memeToken, owner, user1, taxReceiver } = await loadFixture(deployMEMETokenFixture);
      
      // 所有者可以修改
      await memeToken.connect(owner).setTaxAddr(taxReceiver.address);
      expect(await memeToken._taxAddr()).to.equal(taxReceiver.address);
      
      // 非所有者不能修改
      await expect(
        memeToken.connect(user1).setTaxAddr(user1.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("应该正确设置税率（不能超过10%）", async function () {
      const { memeToken, owner } = await loadFixture(deployMEMETokenFixture);
      
      // 正常设置税率
      await memeToken.connect(owner).setTaxRate(5);
      expect(await memeToken._taxRate()).to.equal(5);
      
      // 不能设置超过10%的税率
      await expect(
        memeToken.connect(owner).setTaxRate(15)
      ).to.be.revertedWith("tax rate too high");
      
      // 不能设置0税率
      await expect(
        memeToken.connect(owner).setTaxRate(0)
      ).to.be.revertedWith("postive number required");
    });

    it("应该正确设置交易金额限制", async function () {
      const { memeToken, owner } = await loadFixture(deployMEMETokenFixture);
      
      await memeToken.connect(owner).setAmountLimt(500, ethers.parseEther("5"));
      expect(await memeToken._minAmount()).to.equal(500);
      expect(await memeToken._maxAmount()).to.equal(ethers.parseEther("5"));
      
      // 无效的限制应该失败
      await expect(
        memeToken.connect(owner).setAmountLimt(50, ethers.parseEther("5"))
      ).to.be.revertedWith("invalid min|max transaction amount");
    });
  });

  describe("转账功能与税务机制", function () {
    it("普通转账应该收取手续费", async function () {
      const { memeToken, owner, user1, taxReceiver } = await loadFixture(deployMEMETokenFixture);
      
      const transferAmount = ethers.parseEther("100");
      const taxAmount = (transferAmount * 3n) / 100n;
      const actualReceived = transferAmount - taxAmount;
      
      const initialOwnerBalance = await memeToken.balanceOf(owner.address);
      const initialTaxBalance = await memeToken.balanceOf(taxReceiver.address);
      
      // 执行转账
      await memeToken.connect(owner).transfer(user1.address, transferAmount);
      
      // 检查余额变化
      expect(await memeToken.balanceOf(user1.address)).to.equal(actualReceived);
      expect(await memeToken.balanceOf(taxReceiver.address)).to.equal(initialTaxBalance + taxAmount);
      expect(await memeToken.balanceOf(owner.address)).to.equal(initialOwnerBalance - transferAmount);
    });

    it("转账给税务地址应该免手续费", async function () {
      const { memeToken, owner, taxReceiver } = await loadFixture(deployMEMETokenFixture);
      
      const transferAmount = ethers.parseEther("50");
      const initialTaxBalance = await memeToken.balanceOf(taxReceiver.address);
      
      await memeToken.connect(owner).transfer(taxReceiver.address, transferAmount);
      
      // 税务地址应该收到全额转账
      expect(await memeToken.balanceOf(taxReceiver.address)).to.equal(initialTaxBalance + transferAmount);
    });

    it("应该强制执行交易金额限制", async function () {
      const { memeToken, owner, user1 } = await loadFixture(deployMEMETokenFixture);
      
      // 转账金额太小应该失败
      await expect(
        memeToken.connect(owner).transfer(user1.address, 50)
      ).to.be.revertedWith("invalid transaction value");
      
      // 转账金额太大应该失败
      await expect(
        memeToken.connect(owner).transfer(user1.address, ethers.parseEther("20"))
      ).to.be.revertedWith("invalid transaction value");
    });
  });

  describe("每日交易次数限制", function () {
    it("应该强制执行每日交易次数限制", async function () {
      const { memeToken, owner, user1, user2 } = await loadFixture(deployMEMETokenFixture);
      
      const transferAmount = ethers.parseEther("100");
      
      // 执行5次交易（最大限制）
      for (let i = 0; i < 5; i++) {
        await memeToken.connect(owner).transfer(user1.address, transferAmount);
      }
      
      // 第6次交易应该失败
      await expect(
        memeToken.connect(owner).transfer(user2.address, transferAmount)
      ).to.be.revertedWith("daily transaction limit exceeded");
    });

    it("应该在不同日期重置交易计数", async function () {
      const { memeToken, owner, user1 } = await loadFixture(deployMEMETokenFixture);
      
      const transferAmount = ethers.parseEther("100");
      
      // 执行5次交易
      for (let i = 0; i < 5; i++) {
        await memeToken.connect(owner).transfer(user1.address, transferAmount);
      }
      
      // 模拟时间快进1天
      await ethers.provider.send("evm_increaseTime", [24 * 60 * 60]); // 增加1天
      await ethers.provider.send("evm_mine"); // 挖一个新块
      
      // 现在应该可以再次交易
      await expect(
        memeToken.connect(owner).transfer(user1.address, transferAmount)
      ).not.to.be.reverted;
    });
  });

  describe("Uniswap流动性功能", function () {
    it("应该正确初始化Uniswap路由器", async function () {
      const { memeToken, owner } = await loadFixture(deployMEMETokenFixture);
      
      const result = await memeToken.connect(owner).initUniswapV2Router();
      
      expect(result).to.be.true;
      
      // 可以添加对交易对地址的验证
      // 注意：在实际测试中需要模拟或使用测试网的Uniswap
    });

    it("只有所有者可以初始化路由器", async function () {
      const { memeToken, user1 } = await loadFixture(deployMEMETokenFixture);
      
      await expect(
        memeToken.connect(user1).initUniswapV2Router()
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("资金恢复功能", function () {
    it("所有者可以恢复意外发送的ETH", async function () {
      const { memeToken, owner, user1 } = await loadFixture(deployMEMETokenFixture);
      
      // 先发送一些ETH到合约
      await user1.sendTransaction({
        to: memeToken.target,
        value: ethers.parseEther("1")
      });
      
      const initialContractBalance = await ethers.provider.getBalance(memeToken.target);
      const initialOwnerBalance = await ethers.provider.getBalance(owner.address);
      
      // 恢复ETH
      const tx = await memeToken.connect(owner).recoverETH();
      const receipt = await tx.wait();
      const gasCost = receipt.gasUsed * receipt.gasPrice;
      
      expect(await ethers.provider.getBalance(memeToken.target)).to.equal(0);
      
      // 验证所有者收到ETH（考虑gas费用）
      const finalOwnerBalance = await ethers.provider.getBalance(owner.address);
      expect(finalOwnerBalance).to.be.closeTo(
        initialOwnerBalance + initialContractBalance - gasCost,
        ethers.parseEther("0.01")
      );
    });

    it("非所有者不能恢复资金", async function () {
      const { memeToken, user1 } = await loadFixture(deployMEMETokenFixture);
      
      await expect(
        memeToken.connect(user1).recoverETH()
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("查询功能", function () {
    it("应该正确查询累计手续费", async function () {
      const { memeToken, owner, user1, taxReceiver } = await loadFixture(deployMEMETokenFixture);
      
      const transferAmount = ethers.parseEther("200");
      const expectedTax = (transferAmount * 3n) / 100n;
      
      // 执行几次转账
      await memeToken.connect(owner).transfer(user1.address, transferAmount);
      await memeToken.connect(owner).transfer(user1.address, transferAmount);
      
      const totalTaxes = await memeToken.totalTaxes();
      expect(totalTaxes).to.equal(expectedTax * 2n);
    });
  });

  describe("边界情况和错误处理", function () {
    it("不能转账到零地址", async function () {
      const { memeToken, owner } = await loadFixture(deployMEMETokenFixture);
      
      await expect(
        memeToken.connect(owner).transfer(ethers.ZeroAddress, 1000)
      ).to.be.revertedWith("invalid zero address");
    });

    it("余额不足应该回滚交易", async function () {
      const { memeToken, owner, user1 } = await loadFixture(deployMEMETokenFixture);
      
      const hugeAmount = ethers.parseEther("100000");
      
      await expect(
        memeToken.connect(owner).transfer(user1.address, hugeAmount)
      ).to.be.reverted; // ERC20: transfer amount exceeds balance
    });
  });
});

describe("MEMEToken 升级功能", function () {
  it("应该支持UUPS升级模式", async function () {
    const [owner] = await ethers.getSigners();
    
    const MEMEToken = await ethers.getContractFactory("MEMEToken");
    const memeToken = await MEMEToken.deploy();
    await memeToken.initialize();
    
    // 验证可升级相关函数存在
    expect(typeof memeToken._authorizeUpgrade).to.equal("function");
    
    // 注意：实际升级测试需要部署新的实现合约
    // 这里只是验证升级机制存在
  });
});