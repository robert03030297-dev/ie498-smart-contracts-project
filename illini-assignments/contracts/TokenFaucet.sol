// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./TokenApp.sol";

contract TokenFaucet is TokenApp {
    using SafeERC20 for IERC20;
    uint256 public constant CLAIM_AMOUNT = 100 ether;
    uint256 public constant COOLDOWN = 1 days;
    mapping(address => uint256) public lastRequest;
    mapping(address => bool) public hasRequested;
    event Requested(address indexed user, uint256 amount);
    event Deposited(address indexed user, uint256 amount);
    constructor(IERC20 t) TokenApp(t) {}

    function requestTokens() external nonReentrant {
        require(getRemainingTime(msg.sender) == 0, "Cooldown active");
        require(getFaucetBalance() >= CLAIM_AMOUNT, "Faucet empty");
        hasRequested[msg.sender] = true;
        lastRequest[msg.sender] = block.timestamp;
        token.safeTransfer(msg.sender, CLAIM_AMOUNT);
        emit Requested(msg.sender, CLAIM_AMOUNT);
    }

    function depositTokens(uint256 amount) external nonReentrant {
        require(amount > 0, "Zero amount");
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, amount);
    }

    function getRemainingTime(address user) public view returns (uint256) {
        if (!hasRequested[user] || block.timestamp >= lastRequest[user] + COOLDOWN) return 0;
        return lastRequest[user] + COOLDOWN - block.timestamp;
    }

    function getFaucetBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
