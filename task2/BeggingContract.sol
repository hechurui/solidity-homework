// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BeggingContract {
    // 合约所有者address
    address private _owner;
    
    // 记录捐赠者的捐赠金额
    mapping(address => uint256) private _donations;
    
    // 捐赠事件，记录捐赠者地址和金额
    event Donation(address indexed donor, uint256 amount);

    // 排行榜
    address[3] private _topDonors;
    uint256[3] private _topAmounts;
    
    // 构造函数，设置合约部署者为所有者
    constructor() {
        _owner = msg.sender;
    }
    
    // 仅所有者可调用的修饰符
    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }
    
    /**
     * @dev 捐赠函数，允许用户向合约发送以太币
     */
    function donate() external payable {
        require(msg.value > 0, "Donation amount must be greater than 0");
        
        // 记录捐赠金额
        uint256 newTotal = _donations[msg.sender] + msg.value;
        _donations[msg.sender] = newTotal;

        // 更新排行榜
        updateRanking(msg.sender, newTotal);
        
        // 触发捐赠事件
        emit Donation(msg.sender, msg.value);
    }
    
    /**
     * @dev 提取函数，允许合约所有者提取所有资金
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        // 将合约中的所有以太币转移给所有者
        payable(_owner).transfer(balance);
    }
    
    /**
     * @dev 查询某个地址的捐赠金额
     * @param donor 要查询的捐赠者地址
     * @return 该地址的总捐赠金额
     */
    function getDonation(address donor) external view returns (uint256) {
        return _donations[donor];
    }
    
    /**
     * @dev 获取合约当前余额
     * @return 合约中的以太币余额
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev 获取合约所有者地址
     * @return 合约所有者地址
     */
    function getOwner() external view returns (address) {
        return _owner;
    }


    /**
     * @dev 更新捐赠排行榜
     */
    function updateRanking(address donor, uint256 totalDonation) private {
        // 遍历前三名进行比较
        for (uint i = 0; i < 3; i++) {
            if (totalDonation > _topAmounts[i]) {
                // 从后往前移动排名
                for (uint j = 2; j > i; j--) {
                    _topDonors[j] = _topDonors[j-1];
                    _topAmounts[j] = _topAmounts[j-1];
                }
                // 插入新排名
                _topDonors[i] = donor;
                _topAmounts[i] = totalDonation;
                break;
            }
        }
    }

    /**
     * @dev 获取捐赠排行榜前三名
     * @return 地址数组和对应的金额数组
     */
    function getTopDonors() external view returns (address[3] memory, uint256[3] memory) {
        return (_topDonors, _topAmounts);
    }
}