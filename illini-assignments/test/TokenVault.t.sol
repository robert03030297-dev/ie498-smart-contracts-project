// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./Base.sol";
import "../contracts/TokenVault.sol";

contract TokenVaultTest is Base {
    TokenVault v;

    function setUp() public override {
        super.setUp();
        v = new TokenVault(t);
        allow(address(v), 1000 ether);
    }

    function testDeposit() public {
        vm.prank(A);
        v.deposit(100 ether);
        eq(v.getDepositBalance(A), 100 ether);
        eq(v.getTotalDeposits(), 100 ether);
        eq(t.balanceOf(address(v)), 100 ether);
    }

    function testPartialWithdrawal() public {
        vm.prank(A);
        v.deposit(100 ether);
        vm.prank(A);
        v.withdraw(40 ether);
        eq(v.getDepositBalance(A), 60 ether);
        eq(t.balanceOf(A), 940 ether);
    }

    function testOverdraw() public {
        vm.prank(A);
        v.deposit(10 ether);
        vm.expectRevert();
        vm.prank(A);
        v.withdraw(11 ether);
    }

    function testIsolation() public {
        vm.prank(A);
        v.deposit(10 ether);
        vm.expectRevert();
        vm.prank(B);
        v.withdraw(1);
    }

    function testMultipleUsers() public {
        vm.prank(A);
        v.deposit(10 ether);
        vm.prank(B);
        t.approve(address(v), 20 ether);
        vm.prank(B);
        v.deposit(20 ether);
        eq(v.getTotalDeposits(), 30 ether);
        eq(v.getDepositBalance(A), 10 ether);
        eq(v.getDepositBalance(B), 20 ether);
    }

    function testNoAllowance() public {
        allow(address(v), 0);
        vm.expectRevert();
        vm.prank(A);
        v.deposit(1);
        eq(v.getTotalDeposits(), 0);
    }

    function testZeroDeposit() public {
        vm.expectRevert();
        vm.prank(A);
        v.deposit(0);
    }

    function testDonation() public {
        vm.prank(A);
        v.deposit(10 ether);
        t.transfer(address(v), 5 ether);
        eq(v.getTotalDeposits(), 10 ether);
        eq(t.balanceOf(address(v)), 15 ether);
    }

    function testFuzzConservation(uint96 raw) public {
        uint256 n = uint256(raw) % 1000 ether + 1;
        t.mint(A, n);
        allow(address(v), n);
        vm.prank(A);
        v.deposit(n);
        eq(v.getTotalDeposits(), t.balanceOf(address(v)));
        vm.prank(A);
        v.withdraw(n);
        eq(v.getTotalDeposits(), 0);
    }
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function testAccountingEvents() public {
        vm.expectEmit(true, false, false, true, address(v));
        emit Deposited(A, 10 ether);
        vm.prank(A);
        v.deposit(10 ether);
        vm.expectEmit(true, false, false, true, address(v));
        emit Withdrawn(A, 10 ether);
        vm.prank(A);
        v.withdraw(10 ether);
    }
}
