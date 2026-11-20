// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./Base.sol";
import "../contracts/TokenFaucet.sol";

contract TokenFaucetTest is Base {
    TokenFaucet f;

    function setUp() public override {
        super.setUp();
        f = new TokenFaucet(t);
        t.transfer(address(f), 1000 ether);
    }

    function testFirstClaim() public {
        vm.prank(A);
        f.requestTokens();
        eq(t.balanceOf(A), 1100 ether);
        eq(f.lastRequest(A), 100000);
    }

    function testCooldown() public {
        vm.prank(A);
        f.requestTokens();
        vm.expectRevert();
        vm.prank(A);
        f.requestTokens();
    }

    function testBoundary() public {
        vm.prank(A);
        f.requestTokens();
        vm.warp(186399);
        eq(f.getRemainingTime(A), 1);
        vm.expectRevert();
        vm.prank(A);
        f.requestTokens();
        vm.warp(186400);
        vm.prank(A);
        f.requestTokens();
        eq(f.getRemainingTime(A), 86400);
    }

    function testEmptyRollback() public {
        TokenFaucet empty = new TokenFaucet(t);
        vm.expectRevert();
        vm.prank(A);
        empty.requestTokens();
        require(!empty.hasRequested(A));
    }

    function testDeposit() public {
        allow(address(f), 10 ether);
        vm.prank(A);
        f.depositTokens(10 ether);
        eq(f.getFaucetBalance(), 1010 ether);
    }

    function testIndependentUsers() public {
        vm.prank(A);
        f.requestTokens();
        vm.prank(B);
        f.requestTokens();
        eq(f.getFaucetBalance(), 800 ether);
    }

    function testTimestampZero() public {
        vm.warp(0);
        vm.prank(A);
        f.requestTokens();
        vm.expectRevert();
        vm.prank(A);
        f.requestTokens();
    }

    function testDepositNeedsApproval() public {
        vm.expectRevert();
        vm.prank(A);
        f.depositTokens(1);
    }
    event Requested(address indexed user, uint256 amount);

    function testRequestEvent() public {
        vm.expectEmit(true, false, false, true, address(f));
        emit Requested(A, 100 ether);
        vm.prank(A);
        f.requestTokens();
    }
}
