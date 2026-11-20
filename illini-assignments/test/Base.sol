// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "../contracts/IlliniToken.sol";

interface Vm {
    function prank(address) external;
    function warp(uint256) external;
    function expectRevert() external;
    function expectEmit(bool, bool, bool, bool, address) external;
}

abstract contract Base {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    address constant A = address(0xA11CE);
    address constant B = address(0xB0B);
    address constant C = address(0xCA11);
    address constant D = address(0xDA7A);
    IlliniToken t;

    function setUp() public virtual {
        vm.warp(100000);
        t = new IlliniToken();
        t.transfer(A, 1000 ether);
        t.transfer(B, 1000 ether);
    }

    function eq(uint256 a, uint256 b) internal pure {
        require(a == b, "assert equal");
    }

    function allow(address spender, uint256 amount) internal {
        vm.prank(A);
        t.approve(spender, amount);
    }
}
