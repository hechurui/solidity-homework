// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Auction.sol";
import "./interfaces/ChainlinkPriceOracle.sol";
import "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/ICCIPRouter.sol";

/// @title 拍卖工厂合约
/// @notice 用于创建和管理拍卖合约实例
contract AuctionFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    address public auctionImplementation;
    address public priceOracle;
    address public ccipRouter;
    
    mapping(address => bool) public isAuctionContract;
    address[] public allAuctions;
    
    event AuctionCreated(address indexed auctionContract, address indexed seller);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /// @notice 初始化工厂合约
    /// @param _auctionImplementation 拍卖合约实现地址
    /// @param _priceOracle 价格预言机地址
    /// @param _ccipRouter CCIP路由器地址
    function initialize(
        address _auctionImplementation,
        address _priceOracle,
        address _ccipRouter
    ) initializer public {
        require(_auctionImplementation != address(0), "Invalid auction implementation");
        require(_priceOracle != address(0), "Invalid price oracle");
        require(_ccipRouter != address(0), "Invalid CCIP router");
        
        __Ownable_init();
        __UUPSUpgradeable_init();
        
        auctionImplementation = _auctionImplementation;
        priceOracle = _priceOracle;
        ccipRouter = _ccipRouter;
    }
    
    /// @notice 创建新拍卖
    /// @param _nftContract NFT合约地址
    /// @param _tokenId NFT的tokenId
    /// @param _paymentToken 支付代币地址(0表示ETH)
    /// @param _startTime 开始时间
    /// @param _endTime 结束时间
    /// @param _startPrice 起始价格
    /// @return 新创建的拍卖合约地址
    function createAuction(
        address _nftContract,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startPrice
    ) external returns (address) {
        // 使用CREATE2部署新的拍卖合约代理
        bytes32 salt = keccak256(abi.encodePacked(
            msg.sender,
            _nftContract,
            _tokenId,
            block.timestamp
        ));
        
        Auction auction = Auction(
            address(new bytes(0)) // 实际会被CREATE2替换
        );
        
        // 初始化拍卖合约
        auction.initialize(
            _nftContract,
            _tokenId,
            _paymentToken,
            _startTime,
            _endTime,
            _startPrice,
            priceOracle
        );
        
        address auctionAddress = address(auction);
        
        // 记录拍卖合约
        isAuctionContract[auctionAddress] = true;
        allAuctions.push(auctionAddress);
        
        emit AuctionCreated(auctionAddress, msg.sender);
        
        return auctionAddress;
    }
    
    /// @notice 创建跨链拍卖
    /// @param destinationChainSelector 目标链选择器
    /// @param _nftContract NFT合约地址
    /// @param _tokenId NFT的tokenId
    /// @param _paymentToken 支付代币地址(0表示ETH)
    /// @param _startTime 开始时间
    /// @param _endTime 结束时间
    /// @param _startPrice 起始价格
    function createCrossChainAuction(
        uint64 destinationChainSelector,
        address _nftContract,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startPrice
    ) external {
        // 使用Chainlink CCIP发送跨链消息创建拍卖
        bytes memory data = abi.encodeWithSignature(
            "createAuction(address,uint256,address,uint256,uint256,uint256)",
            _nftContract,
            _tokenId,
            _paymentToken,
            _startTime,
            _endTime,
            _startPrice
        );
        
        // 构建CCIP消息
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encodePacked(address(this)), // 目标链上的工厂合约
            data: data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });
        
        // 估计费用
        uint256 fee = ICCIPRouter(ccipRouter).getFee(
            destinationChainSelector,
            message
        );
        
        // 发送跨链消息
        ICCIPRouter(ccipRouter).ccipSend{value: fee}(
            destinationChainSelector,
            message
        );
    }
    
    /// @notice 处理跨链拍卖创建请求
    function handleCrossChainAuctionCreation(
        address _nftContract,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startPrice,
        address originalSeller
    ) external {
        // 验证消息来自CCIP路由器
        require(msg.sender == ccipRouter, "Only CCIP router can call");
        
        // 创建拍卖
        address auctionAddress = createAuction(
            _nftContract,
            _tokenId,
            _paymentToken,
            _startTime,
            _endTime,
            _startPrice
        );
        
        // 可以在这里添加额外的跨链逻辑
    }
    
    /// @notice 获取所有拍卖合约
    function getAllAuctions() external view returns (address[] memory) {
        return allAuctions;
    }
    
    /// @notice 获取拍卖数量
    function getAuctionCount() external view returns (uint256) {
        return allAuctions.length;
    }
    
    /// @notice 更新拍卖合约实现
    function setAuctionImplementation(address _newImplementation) external onlyOwner {
        require(_newImplementation != address(0), "Invalid implementation");
        auctionImplementation = _newImplementation;
    }
    
    /// @notice 更新价格预言机
    function setPriceOracle(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "Invalid oracle");
        priceOracle = _newOracle;
    }
    
    /// @notice 更新CCIP路由器
    function setCcipRouter(address _newRouter) external onlyOwner {
        require(_newRouter != address(0), "Invalid router");
        ccipRouter = _newRouter;
    }
    
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    
    // 接收ETH用于支付CCIP费用
    receive() external payable {}
}
