// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract test5 {

    /**

        合并两个有序数组 (Merge Sorted Array)
        题目描述：将两个有序数组合并为一个有序数组。

    **/

    function merge(uint[] memory a, uint[] memory b) public pure returns (uint[] memory) {
        uint lenA = a.length;
        uint lenB = b.length;
        uint[] memory result = new uint[](lenA + lenB);
        
        uint i = 0; // a数组的指针
        uint j = 0; // b数组的指针
        
        // 同时遍历两个数组，按大小放入结果
        while (i < lenA && j < lenB) {
            if (a[i] <= b[j]) {
                result[i + j] = a[i]; // 用i+j计算位置，赋值后i自增
                i++;
            } else {
                result[i + j] = b[j]; // 用i+j计算位置，赋值后j自增
                j++;
            }
        }
        // 处理a数组剩余元素
        while (i < lenA) {
            result[i + j] = a[i];
            i++;
        }
        // 处理b数组剩余元素
        while (j < lenB) {
            result[i + j] = b[j];
            j++;
        }
        // 返回
        return result;
    }
    



}