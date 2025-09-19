// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 导入ERC721
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// 从OpenZeppelin导入ERC721和ERC721URIStorage
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// ERC721URIStorage已经继承了ERC721（IPFS元数据链接绑定_setTokenURI在该合约中）
contract MyGraphicNFT is ERC721URIStorage, Ownable {

    // 记录NFT的总数量（用于生成唯一tokenId）
    uint256 private _tokenIdCounter;

    /**
     * @dev 构造函数：初始化NFT名称、符号，初始化tokenId计数器
     * @param nftName NFT名称
     * @param nftSymbol NFT符号
     */
    constructor(string memory nftName, string memory nftSymbol) ERC721(nftName, nftSymbol) Ownable(msg.sender) { // 部署者默认成为所有者
        _tokenIdCounter = 1; // tokenId从1开始
    }


    /**
     * @dev 铸造NFT函数：生成唯一tokenId，关联元数据，转移给接收者
     * @param recipient 接收NFT的钱包地址
     * @param tokenURI IPFS上的NFT元数据JSON链接
     * @return 新铸造NFT的tokenId
     */
    function mintNFT(address recipient, string memory tokenURI) public onlyOwner returns (uint256) { // 仅所有者可铸造
        // 1. 检查接收地址是否合法（非0地址）
        require(recipient != address(0), "recipient to the zero address");
        // 2. 检查元数据链接是否非空
        require(bytes(tokenURI).length > 0, "tokenURI is null");

        // 3. 获取当前tokenId并自增（确保每次铸造唯一）
        uint256 currentTokenId = _tokenIdCounter;
        _tokenIdCounter++;

        // 4. 铸造NFT：调用ERC721的内部函数，将tokenId分配给接收者
        _safeMint(recipient, currentTokenId);
        // 5. 关联元数据：将tokenId与IPFS元数据链接绑定
        _setTokenURI(currentTokenId, tokenURI);

        return currentTokenId; // 返回铸造成功的tokenId（用于后续查询）
    }

}