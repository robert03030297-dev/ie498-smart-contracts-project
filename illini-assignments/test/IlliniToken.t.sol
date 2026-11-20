// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./Base.sol";

contract IlliniTokenTest is Base {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function testMetadata() public {
        require(keccak256(bytes(t.name())) == keccak256("IlliniToken"));
        require(keccak256(bytes(t.symbol())) == keccak256("ILT"));
        eq(t.decimals(), 18);
    }

    function testInitialSupply() public {
        IlliniToken fresh = new IlliniToken();
        eq(fresh.totalSupply(), 1_000_000 ether);
        eq(fresh.balanceOf(address(this)), 1_000_000 ether);
    }

    function testTransferEvent() public {
        vm.expectEmit(true, true, false, true, address(t));
        emit Transfer(A, C, 10 ether);
        vm.prank(A);
        t.transfer(C, 10 ether);
        eq(t.balanceOf(C), 10 ether);
        eq(t.balanceOf(A), 990 ether);
    }

    function testExcessTransfer() public {
        vm.expectRevert();
        vm.prank(A);
        t.transfer(C, 1001 ether);
    }

    function testOwnerMint() public {
        t.mint(C, 5 ether);
        eq(t.balanceOf(C), 5 ether);
        eq(t.totalSupply(), 1_000_005 ether);
    }

    function testUnauthorizedMint() public {
        vm.expectRevert();
        vm.prank(A);
        t.mint(A, 1);
    }

    function testBurn() public {
        vm.prank(A);
        t.burn(5 ether);
        eq(t.balanceOf(A), 995 ether);
        eq(t.totalSupply(), 999_995 ether);
    }

    function testExcessBurn() public {
        vm.expectRevert();
        vm.prank(A);
        t.burn(1001 ether);
    }

    function testZeroRecipient() public {
        vm.expectRevert();
        t.transfer(address(0), 1);
    }
}
