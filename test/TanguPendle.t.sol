// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "../src/TanguPendle.sol";

contract TanguPendleTest is Test {
    TanguPendle public tanguPendle;
    address public user = address(0xA18ce);

    // USDe Pendle Market
    IERC20 public uToken = IERC20(address(0x4c9EDD5852cd905f086C759E8383e09bff1E68B3));
    IERC20 public syToken = IERC20(address(0xb47CBF6697A6518222c7Af4098A43AEFe2739c8c));
    IERC20 public ptToken = IERC20(address(0x917459337CaAC939D41d7493B3999f571D20D667));
    IERC20 public ytToken = IERC20(address(0x733Ee9Ba88f16023146EbC965b7A1Da18a322464));
    IERC20 public lpToken = IERC20(address(0x9Df192D13D61609D1852461c4850595e1F56E714));

    bytes32 public uKey;
    bytes32 public syKey;
    bytes32 public ptKey;
    bytes32 public ytKey;
    bytes32 public lpKey;

    function setUp() public {
        vm.createSelectFork("http://127.0.0.1:8545");

        tanguPendle = new TanguPendle();
        tanguPendle.setMarket(
            address(uToken),
            address(syToken),
            address(ptToken),
            address(ytToken),
            address(lpToken)
        );

        uKey = tanguPendle.getMarketKey(address(lpToken), TanguPendle.TokenType.ERC20);
        syKey = tanguPendle.getMarketKey(address(lpToken), TanguPendle.TokenType.SY);
        ptKey = tanguPendle.getMarketKey(address(lpToken), TanguPendle.TokenType.PT);
        ytKey = tanguPendle.getMarketKey(address(lpToken), TanguPendle.TokenType.YT);
        lpKey = tanguPendle.getMarketKey(address(lpToken), TanguPendle.TokenType.LP);

        deal(address(uToken), address(this), 1_000_000e18);
    }

    function test_0_setMarket() public {
        vm.expectRevert(TanguPendle.InvalidMarket.selector);
        tanguPendle.setMarket(address(0), address(0), address(0), address(0), address(0));

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user)
        );
        tanguPendle.setMarket(address(1), address(2), address(3), address(4), address(5));

        vm.expectEmit(true, true, false, false);
        emit TanguPendle.AddMarket(
            address(5),
            address(1),
            address(2),
            address(3),
            address(4)
        );
        tanguPendle.setMarket(address(1), address(2), address(3), address(4), address(5));

        assertEq(tanguPendle.getMarketInfo(address(5)).uToken, address(1));
        assertEq(tanguPendle.getMarketInfo(address(5)).syToken, address(2));
        assertEq(tanguPendle.getMarketInfo(address(5)).ptToken, address(3));
        assertEq(tanguPendle.getMarketInfo(address(5)).ytToken, address(4));
        assertEq(tanguPendle.getMarketInfo(address(5)).lpToken, address(5));
    }

    function test_1_deposit() public {
        uint depositAmount = 1_000_000e18;
        uint beforeBal = uToken.balanceOf(address(this));
        uToken.approve(address(tanguPendle), depositAmount);
        tanguPendle.deposit(address(lpToken), TanguPendle.TokenType.ERC20, depositAmount);
        uint afterBal = uToken.balanceOf(address(this));

        assertEq(beforeBal - afterBal, depositAmount);
        assertEq(uToken.balanceOf(address(tanguPendle)), depositAmount);
        assertEq(tanguPendle.balanceOf(address(this), uKey), depositAmount);

        vm.expectRevert(TanguPendle.InvalidMarket.selector);
        tanguPendle.deposit(address(111), TanguPendle.TokenType.ERC20, depositAmount);
    }

    function test_2_withdraw() public {
        uint depositAmount = 1_000_000e18;
        uToken.approve(address(tanguPendle), depositAmount);
        tanguPendle.deposit(address(lpToken), TanguPendle.TokenType.ERC20, depositAmount);

        uint beforeBal = uToken.balanceOf(address(this));
        tanguPendle.withdraw(
            address(lpToken),
            TanguPendle.TokenType.ERC20,
            depositAmount / 2
        );
        uint afterBal = uToken.balanceOf(address(this));

        assertEq(afterBal - beforeBal, depositAmount / 2);
        assertEq(tanguPendle.balanceOf(address(this), uKey), depositAmount / 2);

        vm.expectRevert(TanguPendle.InsufficientBalance.selector);
        tanguPendle.withdraw(
            address(lpToken),
            TanguPendle.TokenType.ERC20,
            depositAmount / 2 + 1
        );
    }

    function test_3_switchAsset_from_erc20_to_sy() public {
        uint depositAmount = 1_000_000e18;
        uToken.approve(address(tanguPendle), depositAmount);
        tanguPendle.deposit(address(lpToken), TanguPendle.TokenType.ERC20, depositAmount);

        tanguPendle.switchAsset(
            address(lpToken),
            TanguPendle.TokenType.ERC20,
            TanguPendle.TokenType.SY
        );

        uint syBalance = tanguPendle.balanceOf(address(this), syKey);
        assertGt(syBalance, 0);
        assertEq(syToken.balanceOf(address(tanguPendle)), syBalance);
    }

    function test_4_switchAsset_from_erc20_to_sy_and_withdraw() public {
        uint depositAmount = 1_000_000e18;
        uToken.approve(address(tanguPendle), depositAmount);
        tanguPendle.deposit(address(lpToken), TanguPendle.TokenType.ERC20, depositAmount);

        tanguPendle.switchAsset(
            address(lpToken),
            TanguPendle.TokenType.ERC20,
            TanguPendle.TokenType.SY
        );

        uint syBalance = tanguPendle.balanceOf(address(this), syKey);
        uint beforeBal = syToken.balanceOf(address(this));
        tanguPendle.withdraw(address(lpToken), TanguPendle.TokenType.SY, syBalance);
        uint afterBal = syToken.balanceOf(address(this));

        assertEq(afterBal - beforeBal, syBalance);
        assertEq(tanguPendle.balanceOf(address(this), uKey), 0);
    }

    function test_5_swapPublic_from_erc20_to_sy() public {
        uint depositAmount = 1_000_000e18;
        uToken.approve(address(tanguPendle), depositAmount);
        uint beforeSyBal = syToken.balanceOf(address(this));
        tanguPendle.swapPublic(
            address(lpToken),
            TanguPendle.TokenType.ERC20,
            TanguPendle.TokenType.SY,
            depositAmount
        );
        uint afterSyBal = syToken.balanceOf(address(this));

        assertGt(afterSyBal - beforeSyBal, 0);
        assertEq(uToken.balanceOf(address(this)), 0);
    }

    function test_7_fuzz_switchAsset(uint8 from, uint8 to, uint64 amount) public {
        uint depositAmount = uint(amount) + 1e18;
        TanguPendle.TokenType fromType = TanguPendle.TokenType(from % 5);
        TanguPendle.TokenType toType = TanguPendle.TokenType(to % 5);

        if (depositAmount == 0) {
            vm.expectRevert(TanguPendle.InvalidAmount.selector);
            tanguPendle.switchAsset(address(lpToken), fromType, toType);
        } else {
            IERC20 fromToken = IERC20(tanguPendle.getToken(address(lpToken), fromType));
            IERC20 toToken = IERC20(tanguPendle.getToken(address(lpToken), toType));
            uint toBeforeBal = toToken.balanceOf(address(tanguPendle));
            deal(address(fromToken), address(this), depositAmount);
            fromToken.approve(address(tanguPendle), depositAmount);
            tanguPendle.deposit(address(lpToken), fromType, depositAmount);

            if (fromType == toType) {
                vm.expectRevert(
                    abi.encodeWithSelector(
                        TanguPendle.InvalidSwap.selector,
                        fromType,
                        toType
                    )
                );
                tanguPendle.switchAsset(address(lpToken), fromType, toType);
            } else {
                tanguPendle.switchAsset(address(lpToken), fromType, toType);

                uint toAfterBal = toToken.balanceOf(address(tanguPendle));
                bytes32 toKey = tanguPendle.getMarketKey(address(lpToken), toType);
                uint toBal = tanguPendle.balanceOf(address(this), toKey);

                assertEq(fromToken.balanceOf(address(this)), 0);
                assertEq(fromToken.balanceOf(address(tanguPendle)), 0);
                assertEq(toAfterBal - toBeforeBal, toBal);
            }
        }
    }

    function test_8_fuzz_swapPublic(uint8 from, uint8 to, uint64 amount) public {
        uint swapAmount = uint(amount) + 1e18;
        TanguPendle.TokenType fromType = TanguPendle.TokenType(from % 5);
        TanguPendle.TokenType toType = TanguPendle.TokenType(to % 5);

        IERC20 fromToken = IERC20(tanguPendle.getToken(address(lpToken), fromType));
        IERC20 toToken = IERC20(tanguPendle.getToken(address(lpToken), toType));
        uint toBeforeBal = toToken.balanceOf(address(tanguPendle));
        deal(address(fromToken), address(this), swapAmount);
        fromToken.approve(address(tanguPendle), swapAmount);

        if (swapAmount == 0) {
            vm.expectRevert(TanguPendle.InvalidAmount.selector);
            tanguPendle.swapPublic(address(lpToken), fromType, toType, swapAmount);
        } else if (fromType == toType) {
            vm.expectRevert(
                abi.encodeWithSelector(TanguPendle.InvalidSwap.selector, fromType, toType)
            );
            tanguPendle.swapPublic(address(lpToken), fromType, toType, swapAmount);
        } else {
            tanguPendle.swapPublic(address(lpToken), fromType, toType, swapAmount);

            uint toAfterBal = toToken.balanceOf(address(tanguPendle));
            bytes32 toKey = tanguPendle.getMarketKey(address(lpToken), toType);
            uint toBal = tanguPendle.balanceOf(address(this), toKey);

            assertEq(fromToken.balanceOf(address(this)), 0);
            assertEq(fromToken.balanceOf(address(tanguPendle)), 0);
            assertEq(toAfterBal - toBeforeBal, toBal);
        }
    }
}
