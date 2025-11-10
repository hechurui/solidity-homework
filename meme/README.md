## 单元测试

```bash
forge test -vvv
```



## sepolia 交互

> UniswapV2 spolia 
>
> 来源https://docs.uniswap.org/contracts/v2/reference/smart-contracts/v2-deployments

* 完善.env里面的环境参数

* sepolia 网络部署

  ```bash
  forge script script/DeployMEMEToken.s.sol --rpc-url sepolia  --broadcast  -vvvv
  ```

* 添加流动性，锁定时间60s，代码写在了部署脚本里面 script/DeployMEMEToken.s.sol

   ```
   // 添加流动性, 锁定期 60s
   token.addLiquidity{value: 0.0001 ether}(1 * 10 ** 14, 60);
   console.log("[TokenNum]LP:", token.lpTokenNum());
   console.log("[TokenNum]SavedToPool", token.memeTokenOfPair());
   console.log("[ETH]SaveToPool", token.ethOfPair());
   ```

  部署日志如下，

  ```
  == Logs ==
    [Addr]tax 0x47391418DdD8A0D1FaD18f39DbC8eDF5b661C7C9
    [ID]chain 11155111
    [Addr]MEMEToken: 0xC199fbD4384a291F658d81689eCDb4838C1d274a
    [Addr]proxy 0x8BE6570F81e8ADd4c8e8c8c56460B80D08053eE6
    [Addr]factory 0xF62c03E08ada871A0bEb309762E260a7a6a880E6
    [Addr]pair: 0x70f939b2240bA78d8acA76EAE444A9fe08181116
    [TokenNum]LP: 99999999999000
    [TokenNum]SavedToPool 100000000000000
    [ETH]SaveToPool 0
  ```

  记录 proxy地址 0x8BE6570F81e8ADd4c8e8c8c56460B80D08053eE6 到env文件，方便后续升级使用

* 去除流动性

  ```bash
  cast send  0x8BE6570F81e8ADd4c8e8c8c56460B80D08053eE6  "removeLiquidity()"   --rpc-url sepolia  --private-key   PRIVATE-KEY  -vvvv
  ```

* 查看MEME Token 合约ETH数量

  ```bash
  cast balance 0x8BE6570F81e8ADd4c8e8c8c56460B80D08053eE6  --rpc-url sepolia  -vvvv
  ```

* 提取MEME Token合约ETH

  ```bash
  cast send 0x8BE6570F81e8ADd4c8e8c8c56460B80D08053eE6  "recoverETH()" --rpc-url sepolia  --private-key   PRIVATE-KEY  -vvvv
  
  ```

* 合约升级

  ```bash
  forge script script/upgradeToken.sol --rpc-url sepolia  --broadcast  -vvvv
  ```

## fork sepolia

首先获取最新的区块链blocknumber，比如返回9414567

```
cast block-number --rpc-url sepolia
```

anvil 启动本地fork sepolia 网络

```
anvil --fork-url sepolia --fork-block-number 9414567 --chain-id 31338
```

cast 执行命令中的--rpc-url  sepolia 改为 --rpc-url  http://localhost:8545