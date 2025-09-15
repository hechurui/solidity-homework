// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test4 {

    /**

        用 solidity 实现罗马数字转数整数

    **/


    // 罗马数字符号到数值的映射
    mapping(bytes1 => uint256) private romanValues;

    // 构造函数初始化映射关系
    constructor() {
        romanValues['I'] = 1;
        romanValues['V'] = 5;
        romanValues['X'] = 10;
        romanValues['L'] = 50;
        romanValues['C'] = 100;
        romanValues['D'] = 500;
        romanValues['M'] = 1000;
    }

    function romanToInt(string calldata roman) public view returns (uint256) {
        bytes memory romanBytes = bytes(roman);
        
        uint256 total = 0;
        uint256 previousValue = 0;
        
        // 从右向左遍历罗马数字
        for (uint256 i = uint256(romanBytes.length) - 1; i >= 0; i--) {
            bytes1 currentChar = romanBytes[uint256(i)];
            uint256 currentValue = romanValues[currentChar];
            
            // 如果当前值小于前一个值，则减去当前值
            // 否则加上当前值
            if (currentValue < previousValue) {
                total -= currentValue;
            } else {
                total += currentValue;
            }
            
            previousValue = currentValue;
        }
        
        return total;
    }


}