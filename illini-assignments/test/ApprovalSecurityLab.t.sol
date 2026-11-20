// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./Base.sol";
import "../contracts/ApprovalSecurityLab.sol";

contract ApprovalSecurityLabTest is Base {
    ApprovalSecurityLab lab;

    function setUp() public override {
        super.setUp();
        lab = new ApprovalSecurityLab(t);
    }
    event Observation(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 allowanceBefore,
        uint256 allowanceAfter,
        uint256 balanceBefore,
        uint256 balanceAfter,
        uint256 recipientBefore,
        uint256 recipientAfter
    );

    function testLegitimate() public {
        allow(address(lab), 50 ether);
        vm.prank(A);
        lab.executeApprovedTransfer(A, B, 50 ether);
        eq(lab.checkAllowance(A), 0);
        eq(t.balanceOf(A), 950 ether);
        eq(t.balanceOf(B), 1050 ether);
    }

    function testRedirect() public {
        allow(address(lab), 50 ether);
        vm.prank(C);
        lab.executeApprovedTransfer(A, D, 50 ether);
        eq(t.balanceOf(D), 50 ether);
        eq(t.balanceOf(A), 950 ether);
    }

    function testAboveAllowance() public {
        allow(address(lab), 50 ether);
        vm.expectRevert();
        vm.prank(C);
        lab.executeApprovedTransfer(A, D, 51 ether);
        eq(t.balanceOf(A), 1000 ether);
        eq(lab.checkAllowance(A), 50 ether);
    }

    function testRevocation() public {
        allow(address(lab), 50 ether);
        allow(address(lab), 0);
        vm.expectRevert();
        lab.executeApprovedTransfer(A, D, 1);
    }

    function testLimitedExposure() public {
        allow(address(lab), 50 ether);
        lab.executeApprovedTransfer(A, D, 50 ether);
        vm.expectRevert();
        lab.executeApprovedTransfer(A, D, 1);
        eq(t.balanceOf(D), 50 ether);
    }

    function testUnlimitedFutureFunds() public {
        allow(address(lab), type(uint256).max);
        lab.executeApprovedTransfer(A, D, 1000 ether);
        t.transfer(A, 10 ether);
        lab.executeApprovedTransfer(A, D, 10 ether);
        eq(lab.checkAllowance(A), type(uint256).max);
        eq(t.balanceOf(D), 1010 ether);
    }

    function testInsufficientBalance() public {
        allow(address(lab), type(uint256).max);
        vm.expectRevert();
        lab.executeApprovedTransfer(A, D, 1001 ether);
    }

    function testObservationEvent() public {
        allow(address(lab), 50 ether);
        vm.expectEmit(true, true, false, true, address(lab));
        emit Observation(A, D, 20 ether, 50 ether, 30 ether, 1000 ether, 980 ether, 0, 20 ether);
        lab.executeApprovedTransfer(A, D, 20 ether);
    }
}
