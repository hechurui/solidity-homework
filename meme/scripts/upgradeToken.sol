// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../contracts/MEMEToken.sol";
import "../contracts/MEMETokenV2.sol";

contract UpgradeCounter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");

        // Test before upgrade
        console.log("============ Before Upgrade ============");
        MEMEToken token = MEMEToken(payable(proxyAddress));
        uint256 valueBefore = token.lpTokenNum();
        console.log("[Count]LP token", valueBefore);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new implementation
        MEMETokenV2 tokenV2 = new MEMETokenV2();
        console.log("\n============ Deploying New Implementation ============");
        console.log("New implementation:", address(tokenV2));

        // Upgrade proxy to new implementation
        MEMEToken(payable(proxyAddress)).upgradeToAndCall(
            address(tokenV2),
            "" // Empty bytes string since we don't need to call any initialization function
        );

        vm.stopBroadcast();

        // Test after upgrade
        console.log("\n============ After Upgrade ============");
        MEMETokenV2 upgradedToken = MEMETokenV2(payable(proxyAddress));
        uint256 valueAfter = upgradedToken.lpTokenNum();
        console.log("Count after upgrade:", valueAfter);

        if (valueAfter == valueBefore) {
            console.log("================ upgrade successfully");
        } else {
            console.log("================ upgrade failed");
        }
    }
}