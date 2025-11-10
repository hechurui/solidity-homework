// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 导入 OpenZeppelin 可升级合约库
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// 导入 Uniswap V2 接口
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 用于调试输出
import {console} from "hardhat/console.sol";

/**
 * @title MEMEToken
 * @dev 一个具有交易税、交易限制和流动性管理功能的可升级 MEME 代币合约
 * 特性包括：
 * - 可升级合约设计（UUPS模式）
 * - 交易手续费机制
 * - 交易金额限制
 * - 每日交易次数限制
 * - Uniswap V2 流动性管理
 * - 流动性锁定机制
 */
contract MEMEToken is ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    
    // ============================== 配置参数 ==============================
    
    /// @notice 手续费接收地址
    address public _taxAddr;
    
    /// @notice 交易手续费率（百分比，如5表示5%）
    uint256 public _taxRate;
    
    /// @notice 单次交易最大金额（以代币最小单位计）
    uint256 public _maxAmount;
    
    /// @notice 单次交易最小金额（以代币最小单位计）
    uint256 public _minAmount;
    
    /// @notice 每个地址每日最大交易次数
    uint256 public _maxDailyTransactions;
    
    // ============================== 数据结构 ==============================
    
    /**
     * @dev 每日交易状态记录结构体
     */
    struct DailyStatus {
        uint256 _day;   // 最近交易日期（时间戳除以1天的结果）
        uint256 _count; // 当日的交易次数
    }
    
    /// @notice 地址到每日交易状态的映射
    mapping(address => DailyStatus) _dailyStatus;
    
    // ============================== 流动性相关变量 ==============================
    
    /// @notice Uniswap V2 路由器接口实例
    IUniswapV2Router02 internal _uniswapRouter;
    
    /// @notice 流动性锁定时间戳（解锁时间点）
    uint256 public _lockTimestamp;
    
    /// @notice 代币交易对（Token/ETH）地址
    address internal _pair;
    
    // ============================== 事件定义 ==============================
    
    /**
     * @dev 流动性添加事件
     * @param tokenAmount 添加的代币数量
     * @param ethAmount 添加的ETH数量
     * @param liquidity 获得的LP代币数量
     */
    event LiquidityAdded(
        uint256 tokenAmount,
        uint256 ethAmount,
        uint256 liquidity
    );
    
    /**
     * @dev 流动性移除事件
     * @param tokenAmount 移除获得的代币数量
     * @param ethAmount 移除获得的ETH数量
     */
    event LiquidityRemoved(uint256 tokenAmount, uint256 ethAmount);
    
    // ============================== 修饰器 ==============================
    
    /**
     * @dev 验证数值为正数的修饰器
     * @param val 要验证的数值
     */
    modifier posVal(uint256 val) {
        require(val > 0, "postive number required");
        _;
    }
    
    /**
     * @dev 验证地址不为零地址的修饰器
     * @param addr 要验证的地址
     */
    modifier notZeroAddr(address addr) {
        require(addr != address(0), "invalid zero address ");
        _;
    }
    
    // ============================== UUPS 可升级相关 ==============================
    
    /**
     * @dev 授权合约升级的内部函数（仅合约所有者可调用）
     * @param newImplementation 新实现合约地址
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        // 空实现，仅用于满足接口要求
        // onlyOwner 修饰器确保只有所有者可以授权升级
    }
    
    // ============================== 初始化函数 ==============================
    
    /**
     * @dev 合约初始化函数（替代构造函数）
     * @notice 初始化代币名称、符号、总供应量和各项参数
     */
    function initialize() public initializer {
        // 初始化父合约
        __ERC20_init("MEME", "MM");        // 初始化ERC20代币（名称：MEME，符号：MM）
        __Ownable_init();                  // 初始化所有者权限
        __UUPSUpgradeable_init();          // 初始化UUPS可升级功能
        
        // 发行总供应量：20000 * 10^18 个代币
        uint256 totalSupply = 10000 * 10 ** 18;
        _mint(msg.sender, totalSupply);    // 向部署者地址铸造一半供应量
        _mint(address(this), totalSupply); // 向合约地址铸造另一半供应量（用于流动性提供）
        
        // 初始化各项参数
        _taxAddr = 0x47391418DdD8A0D1FaD18f39DbC8eDF5b661C7C9; // 设置手续费接收地址
        _taxRate = 3;                       // 设置手续费率为3%
        _minAmount = 100;                   // 设置最小交易金额为100wei
        _maxAmount = 10 ether;              // 设置最大交易金额为10ETH（单位：代币最小单位）
        _maxDailyTransactions = 5;          // 设置每日最大交易次数为5次
    }
    
    // ============================== 参数设置函数 ==============================
    
    /**
     * @dev 设置手续费接收地址
     * @param addr 新的手续费接收地址
     */
    function setTaxAddr(address addr) external notZeroAddr(addr) {
        _taxAddr = addr;
    }
    
    /**
     * @dev 设置交易手续费率
     * @param rate 新的手续费率（不能超过10%）
     */
    function setTaxRate(uint256 rate) external posVal(rate) {
        require(rate <= 10, "tax rate too high"); // 手续费率不能超过10%
        _taxRate = rate;
    }
    
    /**
     * @dev 设置交易金额限制
     * @param low 最小交易金额
     * @param high 最大交易金额
     */
    function setAmountLimt(uint256 low, uint256 high) external {
        require(low > 99 && high > low, "invalid min|max transaction amount");
        _maxAmount = high;
        _minAmount = low;
    }
    
    /**
     * @dev 设置每日交易次数限制
     * @param num 每日最大交易次数
     */
    function setDailyLimit(uint256 num) external posVal(num) {
        _maxDailyTransactions = num;
    }
    
    // ============================== Uniswap 流动性管理 ==============================

    
    /**
     * @dev 初始化Uniswap V2路由器并创建交易对
     * @return 初始化是否成功
     * @notice 只能初始化一次，防止重复创建交易对
     */
    function initUniswapV2Router() external returns (bool) {
        require(_pair == address(0), "double init"); // 防止重复初始化
        
        // 初始化Uniswap V2路由器（Sepolia测试网地址）
        _uniswapRouter = IUniswapV2Router02(
            0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3
        );
        
        console.log("[Addr]factory", _uniswapRouter.factory());
        
        // 通过路由器获取工厂合约并创建交易对
        IUniswapV2Factory factory = IUniswapV2Factory(_uniswapRouter.factory());
        _pair = factory.createPair(address(this), _uniswapRouter.WETH());
        
        console.log("[Addr]pair:", _pair);
        return true;
    }
    
    /**
     * @dev 获取代币交易对地址（内部视图函数）
     * @return 交易对合约地址
     */
    function getPair() internal view returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(_uniswapRouter.factory());
        address pair = factory.getPair(address(this), _uniswapRouter.WETH());
        return pair;
    }
    
    // ============================== 交易限制逻辑 ==============================
    
    /**
     * @dev 获取当前日期（内部视图函数）
     * @return 当前时间戳对应的天数
     */
    function _getCurrentDay() internal view returns (uint256) {
        return block.timestamp / 1 days; // 将时间戳转换为天数
    }
    
    /**
     * @dev 检查并更新每日交易限制（内部函数）
     * @notice 如果跨天则重置计数，检查是否超过每日限制
     */
    function _checkAndUpdateDailyLimit() internal {
        uint256 currentDay = _getCurrentDay();
        DailyStatus storage stats = _dailyStatus[msg.sender]; // 获取发送者的交易状态
        
        // 如果是新的一天，重置交易计数
        if (stats._day != currentDay) {
            stats._count = 0;
            stats._day = currentDay;
        }
        
        // 检查是否超过每日交易次数限制
        require(
            stats._count < _maxDailyTransactions,
            "daily transaction limit exceeded"
        );
        
        stats._count++; // 增加交易计数
        // console.log("[DailyCount]", stats._count); // 调试输出
    }
    
    // ============================== 重写ERC20转账函数 ==============================
    
    /**
     * @dev 重写ERC20转账函数，加入交易税和限制检查
     * @param to 接收地址
     * @param value 转账金额
     * @return 转账是否成功
     */
    function transfer(
        address to,
        uint256 value
    ) public virtual override notZeroAddr(to) returns (bool) {
        // 检查并更新每日交易限制
        _checkAndUpdateDailyLimit();
        
        // 检查交易金额是否在允许范围内
        require(
            value >= _minAmount && value <= _maxAmount,
            "invalid transaction value"
        );
        
        // 如果接收方是手续费地址或Uniswap路由器，直接转账（免手续费）
        if (to == _taxAddr || to == address(_uniswapRouter)) {
            return super.transfer(to, value);
        } else {
            // 计算手续费和实际转账金额
            uint256 tax = (value * _taxRate) / 100;
            uint256 valueAfter = value - tax;
            
            // 先转手续费给手续费地址，再转剩余金额给接收方
            return super.transfer(_taxAddr, tax) && super.transfer(to, valueAfter);
        }
    }
    
    // ============================== 查询函数 ==============================
    
    /**
     * @dev 查询累计手续费总额
     * @return 手续费地址当前的代币余额
     */
    function totalTaxes() external view returns (uint256) {
        return balanceOf(_taxAddr);
    }
    
    // ============================== 接收ETH的回退函数 ==============================
    
    /**
     * @dev 接收ETH的fallback函数
     * @notice 允许合约接收ETH，用于添加流动性等操作
     */
    receive() external payable {}
    
    // ============================== 流动性锁定管理 ==============================
    
    /**
     * @dev 锁定流动性（内部函数）
     * @param lockSeconds 锁定时间（秒）
     */
    function lockLiquidity(uint256 lockSeconds) internal onlyOwner {
        require(lockSeconds > 20, "lock period too short"); // 锁定时间至少20秒
        require(_lockTimestamp == 0, "liquidity already locked"); // 防止重复锁定
        
        _lockTimestamp = block.timestamp + lockSeconds; // 设置解锁时间戳
    }
    
    /**
     * @dev 向Uniswap添加流动性
     * @param tokenAmount 要添加的代币数量
     * @param lockSeconds 流动性锁定时间（秒）
     * @notice 需要同时发送ETH（msg.value）作为流动性对
     */
    function addLiquidity(
        uint256 tokenAmount,
        uint256 lockSeconds
    ) external payable onlyOwner {
        require(_pair != address(0), "init router"); // 确保已初始化路由器
        require(tokenAmount > 0, "invalid tokenAmount"); // 验证代币数量
        
        // 锁定流动性
        lockLiquidity(lockSeconds);
        
        // 授权路由器使用代币
        _approve(address(this), address(_uniswapRouter), tokenAmount);
        
        uint256 ethAmount = msg.value;
        
        // 调用Uniswap路由器添加流动性
        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = _uniswapRouter
            .addLiquidityETH{value: ethAmount}(
            address(this),           // 代币地址
            tokenAmount,            // 代币数量
            (tokenAmount * 95) / 100, // 代币数量下限（允许5%滑点）
            (ethAmount * 95) / 100,  // ETH数量下限（允许5%滑点）
            address(this),          // LP代币接收地址（本合约）
            block.timestamp + 300   // 交易过期时间（当前时间+5分钟）
        );
        
        // 处理未使用的ETH（退回给调用者）
        if (ethAmount > amountETH) {
            console.log(
                "owner withdraw eth from contract after remove liquidity",
                ethAmount - amountETH
            );
            payable(owner()).transfer(ethAmount - amountETH);
        }
        
        emit LiquidityAdded(amountToken, amountETH, liquidity);
    }
    
    /**
     * @dev 从Uniswap移除流动性
     * @notice 只能在锁定期满后由所有者调用
     */
    function removeLiquidity() external onlyOwner notZeroAddr(_pair) {
        require(block.timestamp >= _lockTimestamp, "liquidity is still locked"); // 检查锁定状态
        
        // 获取合约持有的LP代币数量
        uint256 liquidity = IERC20(_pair).balanceOf(address(this));
        require(liquidity > 0, "Liquid not enough"); // 确保有流动性可移除
        
        // 授权路由器使用LP代币
        IERC20(_pair).approve(address(_uniswapRouter), liquidity);
        
        // 记录移除前的余额
        uint256 initialTokenBalance = balanceOf(address(this));
        uint256 initialEthBalance = address(this).balance;
        
        // 调用Uniswap路由器移除流动性
        _uniswapRouter.removeLiquidityETH(
            address(this),       // 代币地址
            liquidity,          // 要移除的LP代币数量
            0,                  // 代币数量下限（0表示接受任何数量）
            0,                  // ETH数量下限（0表示接受任何数量）
            address(this),      // 代币和ETH接收地址（本合约）
            block.timestamp + 300 // 交易过期时间
        );
        
        // 计算实际移除的代币和ETH数量
        uint256 tokensReceived = balanceOf(address(this)) - initialTokenBalance;
        uint256 ethReceived = address(this).balance - initialEthBalance;
        
        emit LiquidityRemoved(tokensReceived, ethReceived);
    }
    
    // ============================== 资金恢复函数 ==============================
    
    /**
     * @dev 提取意外发送到合约的ETH
     * @notice 仅合约所有者可调用，用于紧急情况下的资金恢复
     */
    function recoverETH() public onlyOwner {
        uint256 amount = address(this).balance;
        payable(owner()).transfer(amount); // 将合约中的所有ETH转给所有者
    }
    
    /**
     * @dev 提取意外发送到合约的其他ERC20代币
     * @param tokenAddr 要提取的代币合约地址
     * @param to 接收地址
     * @return 提取是否成功
     * @notice 不能提取本合约代币，防止意外流失流动性
     */
    function recoverToken(
        address tokenAddr,
        address to
    ) public onlyOwner returns (bool) {
        require(address(this) != tokenAddr, "can not recover main token"); // 防止提取本合约代币
        uint256 amount = IERC20(tokenAddr).balanceOf(address(this));
        return IERC20(tokenAddr).transfer(to, amount);
    }
    
    // ============================== 流动性信息查询函数 ==============================
    
    /**
     * @dev 查询合约持有的LP代币数量
     * @return LP代币余额
     */
    function lpTokenNum() public view returns (uint256) {
        return IERC20(_pair).balanceOf(address(this));
    }
    
    /**
     * @dev 查询交易对中的本代币数量
     * @return 交易对中的代币余额
     */
    function memeTokenOfPair() public view returns (uint256) {
        return balanceOf(_pair);
    }
    
    /**
     * @dev 查询交易对中的ETH数量
     * @return 交易对合约的ETH余额
     */
    function ethOfPair() public view returns (uint256) {
        return _pair.balance;
    }
}