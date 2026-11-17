// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "../src/Project.sol";

interface Vm {
    function prank(address) external;
    function startPrank(address) external;
    function stopPrank() external;
    function warp(uint256) external;
    function expectRevert() external;
}

contract ProjectTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    address constant A = address(0xA11CE);
    address constant B = address(0xB0B);
    address constant C = address(0xCA11);
    address constant D = address(0xDA7A);
    IlliniToken t;
    TokenFaucet f;
    TokenVault v;
    TokenSpender s;
    TokenMarketplace m;
    TokenEscrow e;
    TokenTimelock l;
    MultisigTreasury q;
    ApprovalSecurityLab lab;

    function setUp() public {
        vm.warp(100000);
        t = new IlliniToken(address(this));
        f = new TokenFaucet(t);
        v = new TokenVault(t);
        s = new TokenSpender(t, B);
        m = new TokenMarketplace(t, B);
        e = new TokenEscrow(t);
        l = new TokenTimelock(t, D, block.timestamp + 1 days);
        q = new MultisigTreasury(t, [A, B, C]);
        lab = new ApprovalSecurityLab(t);
        t.mint(A, 1000 ether);
        t.mint(B, 1000 ether);
        t.mint(address(f), 1000 ether);
        t.mint(address(q), 500 ether);
        t.mint(address(l), 50 ether);
    }

    function eq(uint256 x, uint256 y) internal pure {
        require(x == y, "assert equal");
    }

    function allow(address spender, uint256 amount) internal {
        vm.prank(A);
        t.approve(spender, amount);
    }

    function testTokenMintBurnTransfer() public {
        vm.prank(A);
        t.transfer(C, 10 ether);
        eq(t.balanceOf(C), 10 ether);
        vm.prank(A);
        t.burn(5 ether);
        eq(t.totalSupply(), 3545 ether);
        vm.expectRevert();
        vm.prank(A);
        t.mint(A, 1);
        allow(B, 10 ether);
        vm.prank(B);
        t.burnFrom(A, 10 ether);
        eq(t.allowance(A, B), 0);
    }

    function testTokenInvalidTransfers() public {
        vm.expectRevert();
        vm.prank(A);
        t.transfer(address(0), 1);
        vm.expectRevert();
        vm.prank(D);
        t.transfer(A, 1);
    }

    function testFaucetBoundary() public {
        vm.prank(A);
        f.claim();
        eq(t.balanceOf(A), 1100 ether);
        vm.warp(100000 + 1 days - 1);
        vm.expectRevert();
        vm.prank(A);
        f.claim();
        vm.prank(B);
        f.claim();
        vm.warp(100000 + 1 days);
        vm.prank(A);
        f.claim();
        eq(t.balanceOf(A), 1200 ether);
    }

    function testEmptyFaucetRollback() public {
        TokenFaucet empty = new TokenFaucet(t);
        vm.expectRevert();
        vm.prank(A);
        empty.claim();
        eq(empty.nextClaim(A), 0);
    }

    function testVaultIsolation() public {
        allow(address(v), 100 ether);
        vm.prank(A);
        v.deposit(100 ether);
        vm.expectRevert();
        vm.prank(B);
        v.withdraw(1);
        vm.expectRevert();
        vm.prank(A);
        v.withdraw(101 ether);
        vm.prank(A);
        v.withdraw(100 ether);
        eq(v.totalDeposits(), 0);
        eq(t.balanceOf(A), 1000 ether);
    }

    function testVaultNeedsAllowanceAndRejectsZero() public {
        vm.expectRevert();
        vm.prank(A);
        v.deposit(1);
        vm.expectRevert();
        vm.prank(A);
        v.deposit(0);
        eq(v.totalDeposits(), 0);
    }

    function testSpenderAuthorization() public {
        allow(address(s), 20 ether);
        vm.expectRevert();
        vm.prank(D);
        s.spend(A, D, 10 ether);
        vm.prank(B);
        s.spend(A, C, 20 ether);
        eq(t.balanceOf(C), 20 ether);
        vm.expectRevert();
        vm.prank(B);
        s.spend(A, C, 1);
    }

    function testMarketplace() public {
        vm.expectRevert();
        vm.prank(A);
        m.setProduct(1, 10 ether, true);
        vm.prank(B);
        m.setProduct(1, 10 ether, true);
        allow(address(m), 20 ether);
        vm.prank(A);
        m.buy(1);
        require(m.purchased(A, 1));
        eq(t.balanceOf(B), 1010 ether);
        vm.expectRevert();
        vm.prank(A);
        m.buy(1);
        vm.expectRevert();
        vm.prank(A);
        m.buy(2);
    }

    function testMarketplaceFailedPaymentRollback() public {
        vm.prank(B);
        m.setProduct(1, 10 ether, true);
        vm.expectRevert();
        vm.prank(A);
        m.buy(1);
        require(!m.purchased(A, 1));
    }

    function deal() internal {
        allow(address(e), 20 ether);
        vm.prank(A);
        e.create(B, 20 ether, block.timestamp + 100);
    }

    function testEscrowConfirm() public {
        deal();
        vm.expectRevert();
        vm.prank(C);
        e.confirm(0);
        vm.prank(A);
        e.confirm(0);
        eq(t.balanceOf(B), 1020 ether);
        vm.expectRevert();
        vm.prank(A);
        e.confirm(0);
        vm.expectRevert();
        vm.prank(B);
        e.refund(0);
    }

    function testEscrowDeadlineRefund() public {
        deal();
        vm.expectRevert();
        vm.prank(A);
        e.refund(0);
        vm.warp(block.timestamp + 100);
        vm.expectRevert();
        vm.prank(A);
        e.confirm(0);
        vm.prank(A);
        e.refund(0);
        eq(t.balanceOf(A), 1000 ether);
    }

    function testEscrowSellerRefund() public {
        deal();
        vm.prank(B);
        e.refund(0);
        eq(t.balanceOf(A), 1000 ether);
    }

    function testTimelock() public {
        vm.warp(100000 + 1 days - 1);
        vm.expectRevert();
        l.release();
        vm.warp(100000 + 1 days);
        vm.prank(C);
        l.release();
        eq(t.balanceOf(D), 50 ether);
        vm.expectRevert();
        l.release();
    }

    function testMultisigQuorumReplayAndRevoke() public {
        vm.prank(A);
        q.propose(D, 100 ether);
        vm.prank(A);
        q.approve(0);
        vm.expectRevert();
        vm.prank(A);
        q.approve(0);
        vm.expectRevert();
        vm.prank(A);
        q.execute(0);
        vm.expectRevert();
        vm.prank(D);
        q.approve(0);
        vm.prank(B);
        q.approve(0);
        vm.prank(A);
        q.revoke(0);
        vm.expectRevert();
        vm.prank(B);
        q.execute(0);
        vm.prank(C);
        q.approve(0);
        vm.prank(B);
        q.execute(0);
        eq(t.balanceOf(D), 100 ether);
        vm.expectRevert();
        vm.prank(C);
        q.execute(0);
    }

    function testMultisigInvalidOwners() public {
        vm.expectRevert();
        new MultisigTreasury(t, [A, A, C]);
    }

    function testUnlimitedApprovalDrainsFutureFunds() public {
        allow(address(lab), type(uint256).max);
        vm.prank(D);
        lab.drain(A, 1000 ether);
        eq(t.allowance(A, address(lab)), type(uint256).max);
        t.mint(A, 10 ether);
        vm.prank(D);
        lab.drain(A, 10 ether);
        eq(t.balanceOf(D), 1010 ether);
    }

    function testAllowanceOverwriteRace() public {
        allow(address(lab), 100 ether);
        vm.prank(D);
        lab.drain(A, 100 ether);
        allow(address(lab), 50 ether);
        vm.prank(D);
        lab.drain(A, 50 ether);
        eq(t.balanceOf(D), 150 ether);
    }

    function testRevokeBlocksFutureDrain() public {
        allow(address(lab), type(uint256).max);
        allow(address(lab), 0);
        vm.expectRevert();
        vm.prank(D);
        lab.drain(A, 1);
        eq(t.balanceOf(A), 1000 ether);
    }

    function testExactAllowanceBoundsLoss() public {
        allow(address(lab), 10 ether);
        vm.prank(D);
        lab.drain(A, 10 ether);
        vm.expectRevert();
        vm.prank(D);
        lab.drain(A, 1);
        eq(t.balanceOf(A), 990 ether);
    }

    function testRevokeCannotRecoverSpentTokens() public {
        allow(address(lab), 100 ether);
        vm.prank(D);
        lab.drain(A, 100 ether);
        allow(address(lab), 0);
        eq(t.balanceOf(A), 900 ether);
    }

    function testFuzzVaultConservation(uint96 raw) public {
        uint256 amount = uint256(raw) % 1000 ether + 1;
        t.mint(A, amount);
        allow(address(v), amount);
        vm.prank(A);
        v.deposit(amount);
        eq(v.totalDeposits(), t.balanceOf(address(v)));
        vm.prank(A);
        v.withdraw(amount);
        eq(v.deposits(A), 0);
    }

    function testFuzzTransferSupply(uint96 raw) public {
        uint256 amount = uint256(raw) % 1000 ether;
        uint256 supply = t.totalSupply();
        vm.prank(A);
        t.transfer(B, amount);
        eq(t.totalSupply(), supply);
        eq(t.balanceOf(A) + t.balanceOf(B), 2000 ether);
    }
}
