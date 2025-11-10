pragma solidity ^0.8.0;

import "forge-std/Test.sol";
//import "../contracts/MEMEToken.sol";
import "../contracts/MEMEToken.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract MEMETokenTest is Test {
    MEMEToken public memeToken;
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public uniswapRouter = address(0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3); // Sepolia测试网Router

    function setUp() public {
        // 部署合约并初始化
        vm.prank(owner);
        memeToken = new MEMEToken();
        vm.prank(owner);
        memeToken.initialize();

        // 初始化Uniswap路由
        vm.prank(owner);
        memeToken.initUniswapV2Router();

        // 给测试用户转账
        vm.prank(owner);
        memeToken.transfer(user1, 1000 ether);
        vm.prank(owner);
        memeToken.transfer(user2, 1000 ether);
    }

    // 测试初始化参数
    function testInitialization() public {
        assertEq(memeToken.name(), "MEME");
        assertEq(memeToken.symbol(), "MM");
        assertEq(memeToken.totalSupply(), 20000 ether); // 10000*1e18 * 2（owner+合约）
        assertEq(memeToken._taxRate(), 3);
        assertEq(memeToken._maxDailyTransactions(), 5);
    }

    // 测试转账手续费
    function testTransferWithTax() public {
        uint256 amount = 100 ether;
        uint256 tax = (amount * 3) / 100; // 3%手续费
        uint256 expected = amount - tax;

        vm.prank(user1);
        bool success = memeToken.transfer(user2, amount);
        assertTrue(success);
        assertEq(memeToken.balanceOf(user2), 1000 ether + expected);
        assertEq(memeToken.balanceOf(memeToken._taxAddr()), tax);
    }

    // 测试每日交易次数限制
    function testDailyTransactionLimit() public {
        uint256 maxTx = memeToken._maxDailyTransactions(); // 5次

        // 发送5次交易（正常）
        for (uint256 i = 0; i < maxTx; i++) {
            vm.prank(user1);
            memeToken.transfer(user2, 100 ether);
        }

        // 第6次交易应失败
        vm.prank(user1);
        vm.expectRevert("daily transaction limit exceeded");
        memeToken.transfer(user2, 100 ether);
    }

    // 测试流动性添加（需发送ETH）
    function testAddLiquidity() public {
        uint256 tokenAmount = 1000 ether;
        uint256 ethAmount = 1 ether;

        vm.prank(owner);
        memeToken.approve(address(memeToken), tokenAmount); // 授权合约使用代币

        vm.prank(owner);
        vm.deal(owner, ethAmount); // 给owner充值ETH
        memeToken.addLiquidity{value: ethAmount}(tokenAmount, 86400); // 锁定1天

        // 验证LP代币持有量
        assertGt(memeToken.lpTokenNum(), 0);
    }
}