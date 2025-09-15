// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test3 {

    /**

        用 solidity 实现整数转罗马数字

    **/

    uint256[] private values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    string[] private symbols = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];

    function intToRoman(uint num) public view returns (string memory) {
        // 用 bytes 拼接结果
        bytes memory result = new bytes(0);

        // 从大到小遍历“值-符号”表，逐步拆解整数
        for (uint256 i = 0; i < values.length; i++) {
            // 当前数值 <= 剩余整数时，拼接对应符号并减去数值
            while (num >= values[i]) {
                // 将符号字符串转 bytes 后拼接到结果
                result = abi.encodePacked(result, symbols[i]);
                num -= values[i];
            }
            // 整数减为 0 时 break
            if (num == 0) {
                 break;
            }
        }

        // 将 bytes 转 string 返回
        return string(result);
    }
}