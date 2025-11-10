pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../contracts/MEMEToken.sol";

contract DeployMEMEToken is Script {
    function run() external {
        // 加载私钥（从环境变量获取，避免硬编码）
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署合约
        MEMEToken memeToken = new MEMEToken();
        console.log("MEMEToken deployed at:", address(memeToken));

        // 初始化合约
        memeToken.initialize();
        console.log("MEMEToken initialized");

        // 初始化Uniswap路由（可选，也可后续手动调用）
        memeToken.initUniswapV2Router();
        console.log("Uniswap router initialized");

        vm.stopBroadcast();
    }
}