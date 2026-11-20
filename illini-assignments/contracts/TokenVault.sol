// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./TokenApp.sol";

contract TokenVault is TokenApp {
    using SafeERC20 for IERC20;
    mapping(address => uint256) private deposits;
    uint256 private totalDeposits;
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    constructor(IERC20 t) TokenApp(t) {}

    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Zero amount");
        deposits[msg.sender] += amount;
        totalDeposits += amount;
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0 && amount <= deposits[msg.sender], "Invalid withdrawal");
        deposits[msg.sender] -= amount;
        totalDeposits -= amount;
        token.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getDepositBalance(address user) external view returns (uint256) {
        return deposits[user];
    }

    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }
}
