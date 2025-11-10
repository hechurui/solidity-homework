# MetaNode Stake 系统完整部署教程

本教程将带你一步步完成 MetaNode Stake 质押系统的完整部署流程。

## 📋 目录

1. [环境准备](#环境准备)
2. [项目配置](#项目配置)
3. [本地测试部署](#本地测试部署)
4. [Sepolia测试网部署](#sepolia测试网部署)
5. [合约验证](#合约验证)
6. [合约交互](#合约交互)
7. [合约升级](#合约升级)
8. [常见问题](#常见问题)

---

## 环境准备

### 1. 系统要求

- **Node.js**: v16.0.0 或更高版本
- **npm**: v7.0.0 或更高版本
- **Git**: 用于代码管理

### 2. 安装 Node.js

```bash
# 检查 Node.js 版本
node --version

# 如果版本过低，请从官网下载安装
# https://nodejs.org/
```

### 3. 准备钱包

- 安装 [MetaMask](https://metamask.io/) 浏览器插件
- 创建一个新钱包或导入现有钱包
- 切换到 Sepolia 测试网络

### 4. 获取测试币

Sepolia 测试网 ETH 可以从以下水龙头获取:

- [Sepolia PoW Faucet](https://sepolia-faucet.pk910.de/)
- [Alchemy Sepolia Faucet](https://sepoliafaucet.com/)
- [Infura Sepolia Faucet](https://www.infura.io/faucet/sepolia)

每个水龙头每天可领取 0.5-1 ETH。

### 5. 获取 API Keys

#### Infura/Alchemy (RPC节点)

1. 访问 [Infura](https://infura.io/) 或 [Alchemy](https://www.alchemy.com/)
2. 注册账号
3. 创建新项目
4. 获取 Sepolia 网络的 RPC URL

#### Etherscan (合约验证)

1. 访问 [Etherscan](https://etherscan.io/)
2. 注册账号
3. 生成 API Key: Account → API Keys → Add

---

## 项目配置

### 1. 克隆项目

```bash
git clone <your-repo-url>
cd stake
```

### 2. 安装依赖

```bash
npm install
```

如果遇到依赖冲突，使用:

```bash
npm install --legacy-peer-deps
```

### 3. 配置环境变量

复制示例配置文件:

```bash
cp .env.example .env
```

编辑 `.env` 文件，填入你的配置:

```env
# Sepolia 测试网 RPC URL (从 Infura 或 Alchemy 获取)
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID

# 你的钱包私钥 (不要包含 0x 前缀)
# ⚠️ 警告: 只使用测试钱包的私钥！
PRIVATE_KEY=your_private_key_without_0x

# Etherscan API Key (用于合约验证)
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY

# 可选: 已部署的合约地址 (用于升级或交互)
STAKE_POOL_PROXY_ADDRESS=
META_NODE_TOKEN_ADDRESS=
TEST_TOKEN_ADDRESS=
```

**安全提示:**
- ⚠️ 永远不要提交 `.env` 文件到 Git
- ⚠️ 只使用测试钱包的私钥
- ⚠️ 生产环境使用硬件钱包或多签钱包

---

## 本地测试部署

### 1. 编译合约

```bash
npm run compile
```

成功输出:
```
Compiled 15 Solidity files successfully
```

### 2. 运行测试

```bash
# 运行所有测试
npm test

# 查看 Gas 报告
npm run test:gas

# 生成覆盖率报告
npm run coverage
```

### 3. 本地部署测试

启动本地 Hardhat 节点:

```bash
# 终端 1: 启动节点
npm run node
```

在另一个终端部署:

```bash
# 终端 2: 部署到本地网络
npm run deploy:local
```

---

## Sepolia测试网部署

### 1. 检查钱包余额

```bash
# 使用 Hardhat 控制台检查
npx hardhat console --network sepolia
```

在控制台中:
```javascript
const [deployer] = await ethers.getSigners();
const balance = await ethers.provider.getBalance(deployer.address);
console.log("余额:", ethers.formatEther(balance), "ETH");
```

确保至少有 0.5 ETH 用于部署。

### 2. 执行部署

```bash
npm run deploy:sepolia
```

部署过程输出示例:

```
========================================
Starting MetaNode Stake System Deployment
========================================

Deploying from account: 0x1234...5678
Account balance: 1.5 ETH
Network: sepolia

----------------------------------------
Step 1/6: Deploying MetaNodeToken
----------------------------------------
✅ MetaNodeToken deployed to: 0xabcd...1234
   Gas used: 845,231

----------------------------------------
Step 2/6: Deploying TestToken
----------------------------------------
✅ TestToken deployed to: 0xef12...5678
   Gas used: 723,456

----------------------------------------
Step 3/6: Deploying StakePool Proxy
----------------------------------------
✅ StakePool Implementation deployed to: 0x9876...4321
✅ StakePool Proxy deployed to: 0x5432...8765
   Gas used: 1,234,567

----------------------------------------
Step 4/6: Transferring MetaNode Tokens
----------------------------------------
✅ Transferred 100,000,000 META to StakePool
✅ Transferred 10,000 META to deployer

----------------------------------------
Step 5/6: Creating Initial Pools
----------------------------------------
✅ Pool 0 (ETH) created
✅ Pool 1 (TestToken) created

----------------------------------------
Step 6/6: Minting Test Tokens
----------------------------------------
✅ Minted 1,000,000 TST to deployer

========================================
✅ Deployment Completed Successfully!
========================================

📝 Contract Addresses:
   MetaNodeToken: 0xabcd...1234
   TestToken: 0xef12...5678
   StakePool Proxy: 0x5432...8765
   StakePool Implementation: 0x9876...4321

💾 Deployment info saved to: deployments/sepolia-YYYY-MM-DD-HH-mm-ss.json

⏱️  Total Gas Used: 3,245,678
💰 Estimated Cost: ~0.05 ETH
```

### 3. 保存部署信息

部署信息会自动保存到 `deployments/` 目录:

```json
{
  "network": "sepolia",
  "timestamp": "2024-XX-XX...",
  "deployer": "0x...",
  "contracts": {
    "MetaNodeToken": "0x...",
    "TestToken": "0x...",
    "StakePoolProxy": "0x...",
    "StakePoolImplementation": "0x..."
  },
  "pools": [
    {
      "id": 0,
      "type": "ETH",
      "weight": 100,
      "minDeposit": "0.01",
      "lockBlocks": 6500
    },
    {
      "id": 1,
      "type": "TestToken",
      "weight": 200,
      "minDeposit": "100",
      "lockBlocks": 13000
    }
  ]
}
```

---

## 合约验证

验证合约可以让用户在 Etherscan 上查看和交互合约源码。

### 1. 更新 .env 文件

将部署的合约地址添加到 `.env`:

```env
STAKE_POOL_PROXY_ADDRESS=0x5432...8765
META_NODE_TOKEN_ADDRESS=0xabcd...1234
TEST_TOKEN_ADDRESS=0xef12...5678
```

### 2. 验证 MetaNodeToken

```bash
npx hardhat verify --network sepolia <META_NODE_TOKEN_ADDRESS>
```

### 3. 验证 TestToken

```bash
npx hardhat verify --network sepolia <TEST_TOKEN_ADDRESS> \
  "Test Token" "TST" 18 1000000
```

参数说明:
- `"Test Token"`: 代币名称
- `"TST"`: 代币符号
- `18`: 精度
- `1000000`: 初始供应量

### 4. 验证 StakePool 实现合约

```bash
npx hardhat verify --network sepolia <IMPLEMENTATION_ADDRESS>
```

**注意:** 代理合约通常不需要单独验证，Etherscan 会自动识别。

### 5. 验证成功确认

访问 Etherscan:
```
https://sepolia.etherscan.io/address/<CONTRACT_ADDRESS>
```

你应该看到:
- ✅ 绿色对勾标记
- "Contract" 标签显示源代码
- "Read Contract" 和 "Write Contract" 功能可用

---

## 合约交互

### 方式一: 使用交互脚本

```bash
npm run interact:sepolia
```

脚本功能:
1. 显示合约信息
2. 查询池信息
3. 获取用户余额
4. 执行质押操作（可选）

### 方式二: 使用 Hardhat 控制台

```bash
npx hardhat console --network sepolia
```

在控制台中:

```javascript
// 获取部署账户
const [deployer] = await ethers.getSigners();

// 连接到已部署的合约
const stakePoolAddress = "0x..."; // 你的代理合约地址
const StakePool = await ethers.getContractFactory("StakePool");
const stakePool = StakePool.attach(stakePoolAddress);

// 查询池数量
const poolLength = await stakePool.getPoolLength();
console.log("池数量:", poolLength.toString());

// 查询池信息
const pool0 = await stakePool.pools(0);
console.log("Pool 0:", {
  stToken: pool0.stTokenAddress,
  weight: pool0.poolWeight.toString(),
  minDeposit: ethers.formatEther(pool0.minDepositAmount),
  lockBlocks: pool0.unstakeLockedBlocks.toString()
});

// 质押 ETH (0.1 ETH 到池 0)
const stakeAmount = ethers.parseEther("0.1");
const tx = await stakePool.stake(0, stakeAmount, { value: stakeAmount });
await tx.wait();
console.log("质押成功!");

// 查询待领取奖励
const pending = await stakePool.pendingMetaNode(0, deployer.address);
console.log("待领取奖励:", ethers.formatEther(pending), "META");

// 挖几个区块让奖励累积
for (let i = 0; i < 10; i++) {
  await ethers.provider.send("evm_mine");
}

// 再次查询奖励
const pending2 = await stakePool.pendingMetaNode(0, deployer.address);
console.log("新奖励:", ethers.formatEther(pending2), "META");
```

### 方式三: 使用 Etherscan

1. 访问合约页面
2. 点击 "Write Contract" 或 "Read Contract"
3. 连接 MetaMask 钱包
4. 调用合约函数

**常用函数:**

**质押 ETH (Write Contract):**
- 函数: `stake`
- payableAmount: `0.1` (要质押的 ETH 数量)
- _pid: `0` (池 ID)
- _amount: `100000000000000000` (0.1 ETH in Wei)

**查询奖励 (Read Contract):**
- 函数: `pendingMetaNode`
- _pid: `0`
- _user: `你的钱包地址`

---

## 合约升级

MetaNode Stake 使用可升级代理模式，可以升级合约逻辑而不改变地址。

### 1. 修改 StakePoolV2 或创建新版本

合约位于 `contracts/StakePoolV2.sol`

### 2. 编译新合约

```bash
npm run compile
```

### 3. 执行升级

确保 `.env` 中设置了 `STAKE_POOL_PROXY_ADDRESS`:

```bash
npm run upgrade:sepolia
```

升级输出:

```
========================================
Upgrading StakePool Contract
========================================

Current proxy address: 0x5432...8765
Upgrading to StakePoolV2...

✅ StakePoolV2 deployed to: 0x1111...2222
✅ Proxy upgraded successfully

Verifying upgrade...
✅ Current version: 2.0.0
✅ Bonus multiplier: 100

========================================
✅ Upgrade Completed Successfully!
========================================
```

### 4. 验证升级

```javascript
// 使用 Hardhat 控制台
const StakePoolV2 = await ethers.getContractFactory("StakePoolV2");
const stakePool = StakePoolV2.attach(proxyAddress);

// 检查版本
const version = await stakePool.version();
console.log("版本:", version); // 应该显示 "2.0.0"

// 测试新功能
const bonusMultiplier = await stakePool.bonusMultiplier();
console.log("奖励倍数:", bonusMultiplier.toString());
```

**升级注意事项:**
- ✅ 存储布局必须向后兼容
- ✅ 不能删除现有状态变量
- ✅ 只能在末尾添加新状态变量
- ✅ 不能改变继承顺序
- ⚠️ 升级前在测试网充分测试

---

## 常见问题

### Q1: 部署时提示 "insufficient funds"

**原因:** 钱包余额不足

**解决:**
```bash
# 检查余额
npx hardhat console --network sepolia
const [deployer] = await ethers.getSigners();
console.log(await ethers.provider.getBalance(deployer.address));

# 从水龙头获取更多测试币
```

### Q2: 部署时提示 "nonce too low"

**原因:** Nonce 不同步

**解决:**
```bash
# 清除本地缓存
rm -rf artifacts cache

# 重新编译
npm run compile
```

### Q3: 验证合约失败

**原因:** 构造函数参数不匹配

**解决:**
```bash
# 确保参数顺序和类型完全匹配
npx hardhat verify --network sepolia <ADDRESS> \
  "param1" "param2" 18 1000000

# 查看部署脚本中使用的参数
cat scripts/deploy.js
```

### Q4: 质押时提示 "Amount below minimum deposit"

**原因:** 质押数量小于最小限额

**解决:**
```javascript
// 查询最小质押数量
const pool = await stakePool.pools(0);
console.log("最小质押:", ethers.formatEther(pool.minDepositAmount));

// 确保质押数量 >= 最小值
const stakeAmount = ethers.parseEther("0.1"); // 对于 ETH 池
```

### Q5: 领取奖励时提示 "No pending rewards"

**原因:** 还没有累积奖励

**解决:**
```javascript
// 等待几个区块
for (let i = 0; i < 10; i++) {
  await ethers.provider.send("evm_mine");
}

// 查询奖励
const pending = await stakePool.pendingMetaNode(0, yourAddress);
console.log("待领取:", ethers.formatEther(pending));
```

### Q6: 提取时提示 "No withdrawable amount"

**原因:** 还在锁定期内

**解决:**
```javascript
// 查询可提取数量
const withdrawable = await stakePool.getWithdrawableAmount(0, yourAddress);
console.log("可提取:", ethers.formatEther(withdrawable));

// 查询解质押请求
const userInfo = await stakePool.getUserInfo(0, yourAddress);
console.log("请求列表:", userInfo.requests);

// 等待解锁区块
const currentBlock = await ethers.provider.getBlockNumber();
console.log("当前区块:", currentBlock);
console.log("解锁区块:", userInfo.requests[0].unlockBlock.toString());
```

### Q7: Gas 费用太高

**解决:**
- 使用批量操作减少交易次数
- 在 Gas 价格较低时操作
- 优化合约逻辑（如果是自己修改的）

### Q8: RPC 请求失败

**原因:** Infura/Alchemy 速率限制

**解决:**
- 等待几分钟后重试
- 升级到付费计划
- 使用多个 RPC 提供商

---

## 🎯 下一步

部署完成后，你可以:

1. **测试完整流程:**
   - 质押 ETH 和 ERC20 代币
   - 等待奖励累积
   - 领取奖励
   - 解质押和提取

2. **升级到 V2:**
   - 体验奖励倍数功能
   - 测试升级流程

3. **开发前端:**
   - 参考 [使用示例文档](./使用示例.md)
   - 集成 Web3 库

4. **生产环境部署:**
   - 完整审计合约
   - 使用多签钱包
   - 配置时间锁
   - 准备应急预案

---

## 📚 相关文档

- [README.md](./README.md) - 项目概述
- [STAKE_SYSTEM_ANALYSIS.md](./STAKE_SYSTEM_ANALYSIS.md) - 系统分析
- [TEST_GUIDE.md](./TEST_GUIDE.md) - 测试指南

---

## 🤝 需要帮助?

- 查看 [Issues](https://github.com/your-repo/issues)
- 加入社区讨论
- 联系 MetaNode Academy

---

**免责声明:** 本教程仅供学习参考。生产环境部署前请进行专业审计。

