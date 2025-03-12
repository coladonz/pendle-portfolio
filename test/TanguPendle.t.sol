// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "../src/TanguPendle.sol";

contract TanguPendleTest is Test {
    TanguPendle public tanguPendle;
    address public user = address(0xA18ce);

    function setUp() public {
        tanguPendle = new TanguPendle();
    }

    function test_setMarket() public {
        vm.expectRevert(TanguPendle.InvalidMarket.selector);
        tanguPendle.setMarket(
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0)
        );

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user)
        );
        tanguPendle.setMarket(
            address(1),
            address(2),
            address(3),
            address(4),
            address(5),
            address(6)
        );

        vm.expectEmit(true, true, false, false);
        emit TanguPendle.AddMarket(
            address(1),
            address(2),
            address(3),
            address(4),
            address(5),
            address(6)
        );
        tanguPendle.setMarket(
            address(1),
            address(2),
            address(3),
            address(4),
            address(5),
            address(6)
        );

        assertEq(tanguPendle.getMarketInfo(address(1)).uToken, address(2));
        assertEq(tanguPendle.getMarketInfo(address(1)).syToken, address(3));
        assertEq(tanguPendle.getMarketInfo(address(1)).ptToken, address(4));
        assertEq(tanguPendle.getMarketInfo(address(1)).ytToken, address(5));
        assertEq(tanguPendle.getMarketInfo(address(1)).lpToken, address(6));
    }
}
