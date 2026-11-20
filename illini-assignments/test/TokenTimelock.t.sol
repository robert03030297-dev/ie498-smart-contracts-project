// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./Base.sol";
import "../contracts/TokenTimelock.sol";

contract TokenTimelockTest is Base {
    TokenTimelock l;

    function setUp() public override {
        super.setUp();
        l = new TokenTimelock(t);
        allow(address(l), 100 ether);
        vm.prank(A);
        l.lockTokens(D, 20 ether, 100100);
    }

    function testLockInfo() public {
        TokenTimelock.Lock memory x = l.getLockInfo(0);
        require(x.depositor == A && x.beneficiary == D && !x.withdrawn);
        eq(x.amount, 20 ether);
        eq(x.unlockTime, 100100);
        eq(t.balanceOf(address(l)), 20 ether);
    }

    function testEarly() public {
        vm.warp(100099);
        vm.expectRevert();
        vm.prank(D);
        l.withdrawLockedTokens(0);
    }

    function testExactBoundary() public {
        vm.warp(100100);
        vm.prank(D);
        l.withdrawLockedTokens(0);
        eq(t.balanceOf(D), 20 ether);
        require(l.getLockInfo(0).withdrawn);
    }

    function testWrongCaller() public {
        vm.warp(100100);
        vm.expectRevert();
        vm.prank(A);
        l.withdrawLockedTokens(0);
    }

    function testDoubleWithdrawal() public {
        vm.warp(100100);
        vm.prank(D);
        l.withdrawLockedTokens(0);
        vm.expectRevert();
        vm.prank(D);
        l.withdrawLockedTokens(0);
    }

    function testInvalidInputs() public {
        vm.expectRevert();
        vm.prank(A);
        l.lockTokens(D, 1, 100000);
        vm.expectRevert();
        vm.prank(A);
        l.lockTokens(D, 0, 100100);
        vm.expectRevert();
        vm.prank(A);
        l.lockTokens(address(0), 1, 100100);
    }

    function testIndependentLocks() public {
        vm.prank(A);
        l.lockTokens(D, 30 ether, 100200);
        vm.warp(100100);
        vm.prank(D);
        l.withdrawLockedTokens(0);
        vm.expectRevert();
        vm.prank(D);
        l.withdrawLockedTokens(1);
        vm.warp(100200);
        vm.prank(D);
        l.withdrawLockedTokens(1);
        eq(t.balanceOf(D), 50 ether);
    }

    function testMissingLock() public {
        vm.expectRevert();
        l.getLockInfo(8);
    }
    event Locked(
        uint256 indexed id, address indexed depositor, address indexed beneficiary, uint256 amount, uint256 unlockTime
    );
    event Withdrawn(uint256 indexed id, address indexed beneficiary, uint256 amount);

    function testLockEvents() public {
        vm.expectEmit(true, true, true, true, address(l));
        emit Locked(1, A, D, 10 ether, 100200);
        vm.prank(A);
        l.lockTokens(D, 10 ether, 100200);
        vm.warp(100200);
        vm.expectEmit(true, true, false, true, address(l));
        emit Withdrawn(1, D, 10 ether);
        vm.prank(D);
        l.withdrawLockedTokens(1);
    }
}
