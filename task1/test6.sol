// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract test6{

    /**

        二分查找 (Binary Search)
        题目描述：在一个有序数组中查找目标值。

    **/

    function binarySearch(uint[] memory arr, uint target) public pure returns (int) {
        int left = 0;
        int right = int(arr.length - 1);
        
        while (left <= right) {
            // 计算中间索引
            int mid = left + (right - left) / 2;
            uint midValue = arr[uint(mid)];
            
            // 找到目标值，返回索引
            if (midValue == target) {
                return mid;
            }
            // 目标值在右侧，调整左边界
            else if (midValue < target) {
                left = mid + 1;
            }
            // 目标值在左侧，调整右边界
            else {
                right = mid - 1;
            }
        }
        
        // 未找到目标值
        return -1;
    }

}