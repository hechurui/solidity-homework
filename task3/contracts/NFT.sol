// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title NFT合约
/// @notice 实现ERC721标准的NFT合约，支持铸造和转移
contract NFT is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice 初始化合约
    /// @param name NFT名称
    /// @param symbol NFT符号
    function initialize(string memory name, string memory symbol) initializer public {
        __ERC721_init(name, symbol);
        __Ownable_init();
        __UUPSUpgradeable_init();
        _tokenIdCounter = 1;
    }

    /// @notice 铸造新NFT
    /// @param to 接收者地址
    /// @return 铸造的tokenId
    function mint(address to) public onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    /// @notice 授权拍卖合约转移NFT
    /// @param auctionContract 拍卖合约地址
    /// @param tokenId NFT的tokenId
    function approveAuction(address auctionContract, uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        approve(auctionContract, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}