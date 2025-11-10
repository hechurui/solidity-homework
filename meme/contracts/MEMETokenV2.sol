// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {meme} from "./MEMEToken.sol";

contract MEMETokenV2 is MEMEToken {
    function admin() public view returns (address) {
        return owner();
    }
}