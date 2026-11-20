// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./TokenApp.sol";

contract TokenMarketplace is TokenApp {
    using SafeERC20 for IERC20;
    address public immutable owner;

    struct Product {
        string name;
        uint256 price;
        uint256 stock;
    }
    Product[] private products;
    event ProductAdded(uint256 indexed id, string name, uint256 price, uint256 stock);
    event PriceUpdated(uint256 indexed id, uint256 price);
    event Purchased(address indexed buyer, uint256 indexed id, uint256 price);
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(IERC20 t) TokenApp(t) {
        owner = msg.sender;
    }

    function addProduct(string calldata name, uint256 price, uint256 stock) external onlyOwner returns (uint256 id) {
        require(bytes(name).length > 0 && price > 0, "Invalid product");
        id = products.length;
        products.push(Product(name, price, stock));
        emit ProductAdded(id, name, price, stock);
    }

    function updateProductPrice(uint256 id, uint256 price) external onlyOwner {
        require(price > 0, "Zero price");
        products[id].price = price;
        emit PriceUpdated(id, price);
    }

    function buyProduct(uint256 id) external nonReentrant {
        Product storage p = products[id];
        require(p.stock > 0, "Out of stock");
        p.stock--;
        token.safeTransferFrom(msg.sender, owner, p.price);
        emit Purchased(msg.sender, id, p.price);
    }

    function getProduct(uint256 id) external view returns (Product memory) {
        return products[id];
    }
}
