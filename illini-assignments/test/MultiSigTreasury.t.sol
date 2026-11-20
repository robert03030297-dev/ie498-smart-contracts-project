// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./Base.sol";
import "../contracts/MultiSigTreasury.sol";

contract MultiSigTreasuryTest is Base {
    MultiSigTreasury q;

    function setUp() public override {
        super.setUp();
        q = new MultiSigTreasury(t, [A, B, C]);
        t.transfer(address(q), 100 ether);
        vm.prank(A);
        q.proposeTransfer(D, 20 ether);
    }

    function approveTwo() internal {
        vm.prank(A);
        q.approveTransfer(0);
        vm.prank(B);
        q.approveTransfer(0);
    }

    function testOwners() public {
        require(q.isOwner(A) && q.isOwner(B) && q.isOwner(C) && !q.isOwner(D));
    }

    function testInvalidOwners() public {
        vm.expectRevert();
        new MultiSigTreasury(t, [A, A, C]);
        vm.expectRevert();
        new MultiSigTreasury(t, [A, B, address(0)]);
    }

    function testProposalNoAutoApproval() public {
        eq(q.getApprovalCount(0), 0);
        (address to, uint256 amount,, bool executed) = q.proposals(0);
        require(to == D && !executed);
        eq(amount, 20 ether);
    }

    function testOutsider() public {
        vm.expectRevert();
        vm.prank(D);
        q.proposeTransfer(A, 1);
        vm.expectRevert();
        vm.prank(D);
        q.approveTransfer(0);
        vm.expectRevert();
        vm.prank(D);
        q.executeTransfer(0);
    }

    function testDuplicateApproval() public {
        vm.prank(A);
        q.approveTransfer(0);
        vm.expectRevert();
        vm.prank(A);
        q.approveTransfer(0);
        eq(q.getApprovalCount(0), 1);
    }

    function testOneApproval() public {
        vm.prank(A);
        q.approveTransfer(0);
        vm.expectRevert();
        vm.prank(A);
        q.executeTransfer(0);
    }

    function testTwoApprovals() public {
        approveTwo();
        vm.prank(C);
        q.executeTransfer(0);
        eq(t.balanceOf(D), 20 ether);
    }

    function testReplay() public {
        approveTwo();
        vm.prank(A);
        q.executeTransfer(0);
        vm.expectRevert();
        vm.prank(B);
        q.executeTransfer(0);
    }

    function testInsufficientFundsRollback() public {
        vm.prank(A);
        q.proposeTransfer(D, 101 ether);
        vm.prank(A);
        q.approveTransfer(1);
        vm.prank(B);
        q.approveTransfer(1);
        vm.expectRevert();
        vm.prank(A);
        q.executeTransfer(1);
        (,,, bool executed) = q.proposals(1);
        require(!executed);
    }

    function testMissingProposal() public {
        vm.expectRevert();
        vm.prank(A);
        q.approveTransfer(100);
    }
    event Proposed(uint256 indexed id, address indexed to, uint256 amount);
    event Approved(uint256 indexed id, address indexed owner);
    event Executed(uint256 indexed id);

    function testGovernanceEvents() public {
        vm.expectEmit(true, true, false, true, address(q));
        emit Proposed(1, D, 5 ether);
        vm.prank(A);
        q.proposeTransfer(D, 5 ether);
        vm.expectEmit(true, true, false, true, address(q));
        emit Approved(1, A);
        vm.prank(A);
        q.approveTransfer(1);
        vm.prank(B);
        q.approveTransfer(1);
        vm.expectEmit(true, false, false, true, address(q));
        emit Executed(1);
        vm.prank(A);
        q.executeTransfer(1);
    }
}
