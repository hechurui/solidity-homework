// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**

    任务：参考 openzeppelin-contracts/contracts/token/ERC20/IERC20.sol实现一个简单的 ERC20 代币合约。要求：
    合约包含以下标准 ERC20 功能：
    balanceOf：查询账户余额。
    transfer：转账。
    approve 和 transferFrom：授权和代扣转账。
    使用 event 记录转账和授权操作。
    提供 mint 函数，允许合约所有者增发代币。
    提示：
    使用 mapping 存储账户余额和授权信息。
    使用 event 定义 Transfer 和 Approval 事件。
    部署到sepolia 测试网，导入到自己的钱包

**/

contract MyERC20 {

    // 小数位数
    uint8 public decimals;
    // 总供应量
    uint256 public totalSupply;
    // 存储账户余额
    mapping(address => uint256) private _balances;
    // 存储授权信息: owner => spender => amount
    mapping(address => mapping(address => uint256)) private _allowances;
    // 合约所有者
    address private _owner;
    
    // 转账事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 授权事件
    event Approval(address indexed owner, address indexed spender, uint256 value);


    /**
     * @dev 构造函数，初始化代币信息并将初始供应量分配给合约部署者
     * @param tokenDecimals 小数位数
     * @param initialSupply 初始供应量
     */
    constructor(
        uint8 tokenDecimals,
        uint256 initialSupply
    ) {
        decimals = tokenDecimals;
        _owner = msg.sender;
        
        // 初始供应量分配给合约部署者
        uint256 initialSupplyWithDecimals = initialSupply * (10 **uint256(decimals));
        totalSupply = initialSupplyWithDecimals;
        _balances[msg.sender] = initialSupplyWithDecimals;
        
        emit Transfer(address(0), msg.sender, initialSupplyWithDecimals);
    }

    /**
     * @dev 检查调用者是否为合约所有者
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    /**
     * @dev 增发代币功能，仅合约所有者可调用
     * @param to 接收增发代币的地址
     * @param amount 增发金额
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Mint to the zero address");
        
        uint256 amountWithDecimals = amount * (10** uint256(decimals));
        totalSupply += amountWithDecimals;
        _balances[to] += amountWithDecimals;
        
        emit Transfer(address(0), to, amountWithDecimals);
    }

    /**
     * @dev 查询账户余额
     * @param account 要查询的账户地址
     * @return 账户的代币余额
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev 转账
     * @param recipient 接收者地址
     * @param amount 转账金额
     */
    function transfer(address recipient, uint256 amount) public {
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
    }

    /**
     * @dev 授权
     * @param spender 被授权地址
     * @param amount 授权金额
     */
    function approve(address spender, uint256 amount) public {
        require(spender != address(0), "Approve to the zero address");
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        _allowances[msg.sender][spender] = amount;
        
        emit Approval(msg.sender, spender, amount);
    }
    

    /**
     * @dev 查询授权额度
     * @param owner 授权者地址
     * @param spender 被授权地址
     * @return 剩余授权额度
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }


    /**
     * @dev 授权转账
     * @param sender 资金来源地址
     * @param recipient 接收者地址
     * @param amount 转账金额
     * @return 转账是否成功
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[sender] >= amount, "Insufficient balance");
        require(_allowances[sender][msg.sender] >= amount, "Allowance exceeded");
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        
        emit Transfer(sender, recipient, amount);
        return true;
    }


}