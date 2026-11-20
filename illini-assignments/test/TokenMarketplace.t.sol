// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./Base.sol";
import "../contracts/TokenMarketplace.sol";

contract TokenMarketplaceTest is Base {
    TokenMarketplace m;

    function setUp() public override {
        super.setUp();
        m = new TokenMarketplace(t);
        m.addProduct("Book", 10 ether, 2);
        allow(address(m), 100 ether);
    }

    function testProduct() public {
        TokenMarketplace.Product memory p = m.getProduct(0);
        require(keccak256(bytes(p.name)) == keccak256("Book"));
        eq(p.price, 10 ether);
        eq(p.stock, 2);
    }

    function testOwnerOnly() public {
        vm.expectRevert();
        vm.prank(A);
        m.addProduct("X", 1, 1);
        vm.expectRevert();
        vm.prank(A);
        m.updateProductPrice(0, 1);
    }

    function testPurchase() public {
        uint256 beforeBalance = t.balanceOf(address(this));
        vm.prank(A);
        m.buyProduct(0);
        eq(m.getProduct(0).stock, 1);
        eq(t.balanceOf(address(this)), beforeBalance + 10 ether);
    }

    function testMissingProduct() public {
        vm.expectRevert();
        vm.prank(A);
        m.buyProduct(1);
    }

    function testOutOfStock() public {
        vm.prank(A);
        m.buyProduct(0);
        vm.prank(A);
        m.buyProduct(0);
        vm.expectRevert();
        vm.prank(A);
        m.buyProduct(0);
    }

    function testPaymentRollback() public {
        allow(address(m), 0);
        vm.expectRevert();
        vm.prank(A);
        m.buyProduct(0);
        eq(m.getProduct(0).stock, 2);
    }

    function testPriceUpdate() public {
        m.updateProductPrice(0, 20 ether);
        vm.prank(A);
        m.buyProduct(0);
        eq(t.balanceOf(A), 980 ether);
    }

    function testInsufficientBalance() public {
        m.updateProductPrice(0, 1001 ether);
        allow(address(m), type(uint256).max);
        vm.expectRevert();
        vm.prank(A);
        m.buyProduct(0);
        eq(m.getProduct(0).stock, 2);
    }
    event Purchased(address indexed buyer, uint256 indexed id, uint256 price);

    function testPurchaseEvent() public {
        vm.expectEmit(true, true, false, true, address(m));
        emit Purchased(A, 0, 10 ether);
        vm.prank(A);
        m.buyProduct(0);
    }
}
