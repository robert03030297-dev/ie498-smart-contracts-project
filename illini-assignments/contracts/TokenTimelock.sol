// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./TokenApp.sol";

contract TokenTimelock is TokenApp {
    using SafeERC20 for IERC20;

    struct Lock {
        address depositor;
        address beneficiary;
        uint256 amount;
        uint256 unlockTime;
        bool withdrawn;
    }
    Lock[] private locks;
    event Locked(
        uint256 indexed id, address indexed depositor, address indexed beneficiary, uint256 amount, uint256 unlockTime
    );
    event Withdrawn(uint256 indexed id, address indexed beneficiary, uint256 amount);
    constructor(IERC20 t) TokenApp(t) {}

    function lockTokens(address beneficiary, uint256 amount, uint256 unlockTime)
        external
        nonReentrant
        returns (uint256 id)
    {
        require(beneficiary != address(0) && amount > 0 && unlockTime > block.timestamp, "Invalid lock");
        id = locks.length;
        locks.push(Lock(msg.sender, beneficiary, amount, unlockTime, false));
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Locked(id, msg.sender, beneficiary, amount, unlockTime);
    }

    function withdrawLockedTokens(uint256 id) external nonReentrant {
        Lock storage l = locks[id];
        require(msg.sender == l.beneficiary, "Only beneficiary");
        require(!l.withdrawn && block.timestamp >= l.unlockTime, "Locked or withdrawn");
        l.withdrawn = true;
        token.safeTransfer(l.beneficiary, l.amount);
        emit Withdrawn(id, l.beneficiary, l.amount);
    }

    function getLockInfo(uint256 id) external view returns (Lock memory) {
        return locks[id];
    }
}
