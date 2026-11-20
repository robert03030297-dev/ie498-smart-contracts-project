// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./TokenApp.sol";

/// @notice Only the payer can initiate a payment; the payee is fixed at deployment.
contract TokenSpender is TokenApp {
    using SafeERC20 for IERC20;
    address public immutable payee;
    mapping(address => uint256) public totalPaid;
    event Payment(address indexed payer, address indexed payee, uint256 amount);

    constructor(IERC20 t, address recipient) TokenApp(t) {
        require(recipient != address(0), "Zero payee");
        payee = recipient;
    }

    function spendTokens(address from, uint256 amount) external nonReentrant {
        require(msg.sender == from, "Only payer");
        require(amount > 0, "Zero amount");
        totalPaid[from] += amount;
        token.safeTransferFrom(from, payee, amount);
        emit Payment(from, payee, amount);
    }

    function checkAllowance(address user) external view returns (uint256) {
        return token.allowance(user, address(this));
    }

    function checkBalance(address user) external view returns (uint256) {
        return token.balanceOf(user);
    }
}
