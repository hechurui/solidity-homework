## 项目结构

```
nft-auction-platform/
├── contracts/
│   ├── NFT.sol               # ERC721 实现
│   ├── Auction.sol           # 拍卖合约
│   ├── AuctionFactory.sol   # 工厂合约
│   ├── interfaces/           # 接口定义
│   └── upgrades/             # 升级相关合约
├── scripts/                  # 部署脚本
├── test/                     # 测试文件
├── hardhat.config.js         # Hardhat 配置
└── README.md                 # 项目文档
```

## 依赖包安装

```bash
 npm install @openzeppelin/contracts
 npm install @openzeppelin/contracts-upgradeable
 npm install @chainlink/contracts-ccip
```

## 部署合约

```bash
 npx hardhat run scripts/deploy.js --network sepolia
```