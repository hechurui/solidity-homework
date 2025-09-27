// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

/// @title Chainlink价格预言机
/// @notice 用于获取代币对美元的价格
contract ChainlinkPriceOracle {
    mapping(address => address) public priceFeeds; // 代币地址 => 价格feed地址
    
    /// @notice 构造函数，初始化价格feed
    /// @param tokens 代币地址数组
    /// @param feeds 对应的价格feed地址数组
    constructor(address[] memory tokens, address[] memory feeds) {
        require(tokens.length == feeds.length, "Mismatched arrays");
        for (uint256 i = 0; i < tokens.length; i++) {
            priceFeeds[tokens[i]] = feeds[i];
        }
    }
    
    /// @notice 获取代币对美元的价格
    /// @param token 代币地址，0地址表示ETH
    /// @return 价格（美元）
    function getPriceInUSD(address token) public view returns (uint256) {
        address feedAddress = priceFeeds[token];
        require(feedAddress != address(0), "No price feed available");
        
        (, int256 price, , uint256 updatedAt, ) = AggregatorV3Interface(feedAddress).latestRoundData();
        require(updatedAt > 0, "Round not complete");
        require(price > 0, "Invalid price");
        
        uint8 decimals = AggregatorV3Interface(feedAddress).decimals();
        return uint256(price) * (10 ** (18 - decimals));
    }
    
    /// @notice 将代币金额转换为美元价值
    /// @param token 代币地址，0地址表示ETH
    /// @param amount 代币数量
    /// @return 美元价值
    function convertToUSD(address token, uint256 amount) public view returns (uint256) {
        uint256 price = getPriceInUSD(token);
        return (amount * price) / 10 ** 18;
    }
}
