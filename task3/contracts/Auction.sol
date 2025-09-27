// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAuction.sol";
import "./interfaces/ChainlinkPriceOracle.sol";

/// @title 拍卖合约
/// @notice 实现NFT拍卖功能，支持ERC20和ETH出价
contract Auction is Initializable, IAuction, UUPSUpgradeable, OwnableUpgradeable {
    AuctionInfo public auctionInfo;
    ChainlinkPriceOracle public priceOracle;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /// @notice 初始化拍卖
    /// @param _nftContract NFT合约地址
    /// @param _tokenId NFT的tokenId
    /// @param _paymentToken 支付代币地址(0表示ETH)
    /// @param _startTime 开始时间
    /// @param _endTime 结束时间
    /// @param _startPrice 起始价格
    /// @param _priceOracle 价格预言机地址
    function initialize(
        address _nftContract,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startPrice,
        address _priceOracle
    ) initializer public {
        require(_nftContract != address(0), "Invalid NFT contract");
        require(_startTime < _endTime, "Invalid time range");
        require(_startPrice > 0, "Invalid start price");
        require(_priceOracle != address(0), "Invalid price oracle");
        
        __Ownable_init();
        __UUPSUpgradeable_init();
        
        address seller = msg.sender;
        require(
            IERC721(_nftContract).ownerOf(_tokenId) == seller,
            "Not the NFT owner"
        );
        require(
            IERC721(_nftContract).isApprovedForAll(seller, address(this)) ||
            IERC721(_nftContract).getApproved(_tokenId) == address(this),
            "Auction contract not approved"
        );
        
        // 转移NFT到拍卖合约
        IERC721(_nftContract).transferFrom(seller, address(this), _tokenId);
        
        auctionInfo = AuctionInfo({
            nftContract: _nftContract,
            tokenId: _tokenId,
            seller: seller,
            paymentToken: _paymentToken,
            startTime: _startTime,
            endTime: _endTime,
            startPrice: _startPrice,
            highestBid: 0,
            highestBidder: address(0),
            ended: false,
            cancelled: false
        });
        
        priceOracle = ChainlinkPriceOracle(_priceOracle);
    }
    
    /// @notice 出价
    /// @param amount 出价金额
    function bid(uint256 amount) external payable override {
        AuctionInfo storage info = auctionInfo;
        
        require(!info.ended, "Auction already ended");
        require(!info.cancelled, "Auction cancelled");
        require(block.timestamp >= info.startTime, "Auction not started");
        require(block.timestamp < info.endTime, "Auction ended");
        require(msg.sender != info.seller, "Seller cannot bid");
        
        // 验证出价金额
        if (info.paymentToken == address(0)) {
            // ETH出价
            require(msg.value == amount, "Incorrect ETH amount");
        } else {
            // ERC20出价
            require(msg.value == 0, "Cannot send ETH for ERC20 auction");
            require(
                IERC20(info.paymentToken).allowance(msg.sender, address(this)) >= amount,
                "Token allowance insufficient"
            );
        }
        
        // 转换为美元比较
        uint256 currentBidUsd = priceOracle.convertToUSD(info.paymentToken, amount);
        uint256 highestBidUsd = info.highestBid > 0 
            ? priceOracle.convertToUSD(info.paymentToken, info.highestBid) 
            : priceOracle.convertToUSD(info.paymentToken, info.startPrice);
        
        require(currentBidUsd > highestBidUsd, "Bid not higher than current highest");
        
        // 处理之前的最高出价者退款
        if (info.highestBidder != address(0) && info.highestBid > 0) {
            _refund(info.highestBidder, info.highestBid);
        }
        
        // 更新最高出价
        info.highestBid = amount;
        info.highestBidder = msg.sender;
        
        // 接收ERC20代币
        if (info.paymentToken != address(0)) {
            bool success = IERC20(info.paymentToken).transferFrom(
                msg.sender,
                address(this),
                amount
            );
            require(success, "Token transfer failed");
        }
        
        emit BidPlaced(msg.sender, amount);
    }
    
    /// @notice 结束拍卖
    function endAuction() external override {
        AuctionInfo storage info = auctionInfo;
        
        require(!info.ended, "Auction already ended");
        require(!info.cancelled, "Auction cancelled");
        require(block.timestamp >= info.endTime, "Auction not ended yet");
        require(msg.sender == info.seller || msg.sender == owner(), "Unauthorized");
        
        info.ended = true;
        
        if (info.highestBidder != address(0) && info.highestBid > 0) {
            // 转移NFT给最高出价者
            IERC721(info.nftContract).transferFrom(
                address(this),
                info.highestBidder,
                info.tokenId
            );
            
            // 转移资金给卖家
            _transferToSeller(info.highestBid);
            
            emit AuctionEnded(info.highestBidder, info.highestBid);
        } else {
            // 没有出价，将NFT返还给卖家
            IERC721(info.nftContract).transferFrom(
                address(this),
                info.seller,
                info.tokenId
            );
            
            emit AuctionEnded(address(0), 0);
        }
    }
    
    /// @notice 取消拍卖
    function cancelAuction() external override {
        AuctionInfo storage info = auctionInfo;
        
        require(!info.ended, "Auction already ended");
        require(!info.cancelled, "Auction already cancelled");
        require(
            msg.sender == info.seller || msg.sender == owner(),
            "Only seller or owner can cancel"
        );
        require(
            block.timestamp < info.startTime || info.highestBidder == address(0),
            "Cannot cancel active auction with bids"
        );
        
        info.cancelled = true;
        
        // 将NFT返还给卖家
        IERC721(info.nftContract).transferFrom(
            address(this),
            info.seller,
            info.tokenId
        );
        
        emit AuctionCancelled();
    }
    
    /// @notice 获取拍卖信息
    /// @return 拍卖信息结构体
    function getAuctionInfo() external view override returns (AuctionInfo memory) {
        return auctionInfo;
    }
    
    /// @notice 退款给之前的出价者
    function _refund(address bidder, uint256 amount) internal {
        if (auctionInfo.paymentToken == address(0)) {
            // ETH退款
            (bool success, ) = bidder.call{value: amount}("");
            require(success, "ETH refund failed");
        } else {
            // ERC20退款
            bool success = IERC20(auctionInfo.paymentToken).transfer(bidder, amount);
            require(success, "Token refund failed");
        }
    }
    
    /// @notice 转移资金给卖家
    function _transferToSeller(uint256 amount) internal {
        if (auctionInfo.paymentToken == address(0)) {
            // ETH转账
            (bool success, ) = auctionInfo.seller.call{value: amount}("");
            require(success, "ETH transfer to seller failed");
        } else {
            // ERC20转账
            bool success = IERC20(auctionInfo.paymentToken).transfer(auctionInfo.seller, amount);
            require(success, "Token transfer to seller failed");
        }
    }
    
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    
    // 接收ETH
    receive() external payable {}
}
