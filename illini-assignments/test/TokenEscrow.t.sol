// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./Base.sol";
import "../contracts/TokenEscrow.sol";

contract TokenEscrowTest is Base {
    TokenEscrow e;

    function setUp() public override {
        super.setUp();
        e = new TokenEscrow(t);
        allow(address(e), 100 ether);
        vm.prank(A);
        e.createEscrow(B, 20 ether, 100100);
    }

    function testFunded() public {
        eq(t.balanceOf(address(e)), 20 ether);
        eq(uint256(e.getEscrowStatus(0)), 0);
    }

    function testRelease() public {
        vm.prank(A);
        e.confirmDelivery(0);
        eq(t.balanceOf(B), 1020 ether);
        eq(uint256(e.getEscrowStatus(0)), 1);
    }

    function testDoubleRelease() public {
        vm.prank(A);
        e.confirmDelivery(0);
        vm.expectRevert();
        vm.prank(A);
        e.confirmDelivery(0);
    }

    function testUnauthorizedRelease() public {
        vm.expectRevert();
        vm.prank(B);
        e.confirmDelivery(0);
        vm.expectRevert();
        vm.prank(C);
        e.confirmDelivery(0);
    }

    function testEarlyRefund() public {
        vm.warp(100099);
        vm.expectRevert();
        vm.prank(A);
        e.requestRefund(0);
    }

    function testDeadlineRefund() public {
        vm.warp(100100);
        vm.expectRevert();
        vm.prank(A);
        e.confirmDelivery(0);
        vm.prank(A);
        e.requestRefund(0);
        eq(t.balanceOf(A), 1000 ether);
        eq(uint256(e.getEscrowStatus(0)), 2);
    }

    function testReleaseThenRefund() public {
        vm.prank(A);
        e.confirmDelivery(0);
        vm.warp(100100);
        vm.expectRevert();
        vm.prank(A);
        e.requestRefund(0);
    }

    function testRefundThenReleaseAndRefund() public {
        vm.warp(100100);
        vm.prank(A);
        e.requestRefund(0);
        vm.expectRevert();
        vm.prank(A);
        e.confirmDelivery(0);
        vm.expectRevert();
        vm.prank(A);
        e.requestRefund(0);
    }

    function testUnauthorizedRefund() public {
        vm.warp(100100);
        vm.expectRevert();
        vm.prank(B);
        e.requestRefund(0);
        vm.expectRevert();
        vm.prank(C);
        e.requestRefund(0);
    }

    function testInvalidCreation() public {
        vm.expectRevert();
        vm.prank(A);
        e.createEscrow(address(0), 1, 100101);
        vm.expectRevert();
        vm.prank(A);
        e.createEscrow(B, 0, 100101);
        vm.expectRevert();
        vm.prank(A);
        e.createEscrow(B, 1, 100000);
    }
    event Settled(uint256 indexed id, TokenEscrow.Status status);

    function testSettlementEvent() public {
        vm.expectEmit(true, false, false, true, address(e));
        emit Settled(0, TokenEscrow.Status.Released);
        vm.prank(A);
        e.confirmDelivery(0);
    }
}
