// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import "./NFT.sol";

// 测试 UUPS 升级
contract NFTV2 is NFT {
    // 新增示例方法用于验证升级生效
    function funcV2() external pure returns (string memory) {
        return "hello from V2!";
    }
}