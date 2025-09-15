// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test2 {

    /**
        反转一个字符串。输入 "abcde"，输出 "edcba"
    **/
    function reverseString(string memory inStr) public pure returns (string memory) {
        // 将传入字符串转为byte数组
        bytes memory inBytes = bytes(inStr);
        uint byteLen = inBytes.length;

        // 返回byte数组
        bytes memory outBytes = new bytes(byteLen);

        // 反转
        for (uint i = 0; i < byteLen; i++) {
            outBytes[i] = inBytes[byteLen - 1 - i];
        }
        // 返回，将返回byte数组转换为string
        return string(outBytes);
    }

}