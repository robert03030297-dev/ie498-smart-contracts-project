// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./Base.sol";
import "../contracts/TokenSpender.sol";

contract TokenSpenderTest is Base {
    TokenSpender s;

    function setUp() public override {
        super.setUp();
        s = new TokenSpender(t, C);
    }

    function testPayment() public {
        allow(address(s), 50 ether);
        vm.prank(A);
        s.spendTokens(A, 20 ether);
        eq(s.checkAllowance(A), 30 ether);
        eq(s.checkBalance(A), 980 ether);
        eq(s.totalPaid(A), 20 ether);
        eq(t.balanceOf(C), 20 ether);
    }

    function testNoApproval() public {
        vm.expectRevert();
        vm.prank(A);
        s.spendTokens(A, 1);
    }

    function testAboveAllowance() public {
        allow(address(s), 10);
        vm.expectRevert();
        vm.prank(A);
        s.spendTokens(A, 11);
    }

    function testAboveBalance() public {
        allow(address(s), type(uint256).max);
        vm.expectRevert();
        vm.prank(A);
        s.spendTokens(A, 1001 ether);
        eq(s.totalPaid(A), 0);
    }

    function testUnauthorized() public {
        allow(address(s), 100);
        vm.expectRevert();
        vm.prank(B);
        s.spendTokens(A, 10);
    }

    function testRevoked() public {
        allow(address(s), 100);
        allow(address(s), 0);
        vm.expectRevert();
        vm.prank(A);
        s.spendTokens(A, 1);
    }

    function testZeroPayee() public {
        vm.expectRevert();
        new TokenSpender(t, address(0));
    }
    event Payment(address indexed payer, address indexed payee, uint256 amount);

    function testPaymentEvent() public {
        allow(address(s), 10 ether);
        vm.expectEmit(true, true, false, true, address(s));
        emit Payment(A, C, 10 ether);
        vm.prank(A);
        s.spendTokens(A, 10 ether);
    }
}
