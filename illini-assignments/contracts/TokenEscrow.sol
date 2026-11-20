// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./TokenApp.sol";

contract TokenEscrow is TokenApp {
    using SafeERC20 for IERC20;
    enum Status {
        Funded,
        Released,
        Refunded
    }

    struct Escrow {
        address buyer;
        address seller;
        uint256 amount;
        uint256 deadline;
        Status status;
    }
    Escrow[] public escrows;
    event Created(uint256 indexed id, address indexed buyer, address indexed seller, uint256 amount, uint256 deadline);
    event Settled(uint256 indexed id, Status status);
    constructor(IERC20 t) TokenApp(t) {}

    function createEscrow(address seller, uint256 amount, uint256 deadline) external nonReentrant returns (uint256 id) {
        require(
            seller != address(0) && seller != msg.sender && amount > 0 && deadline > block.timestamp, "Invalid escrow"
        );
        id = escrows.length;
        escrows.push(Escrow(msg.sender, seller, amount, deadline, Status.Funded));
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Created(id, msg.sender, seller, amount, deadline);
    }

    function confirmDelivery(uint256 id) external nonReentrant {
        Escrow storage e = escrows[id];
        require(msg.sender == e.buyer, "Only buyer");
        require(e.status == Status.Funded && block.timestamp < e.deadline, "Not releasable");
        e.status = Status.Released;
        token.safeTransfer(e.seller, e.amount);
        emit Settled(id, e.status);
    }

    /// @notice Buyer only, at or after the deadline; no seller or stranger may refund.
    function requestRefund(uint256 id) external nonReentrant {
        Escrow storage e = escrows[id];
        require(msg.sender == e.buyer, "Only buyer");
        require(e.status == Status.Funded && block.timestamp >= e.deadline, "Not refundable");
        e.status = Status.Refunded;
        token.safeTransfer(e.buyer, e.amount);
        emit Settled(id, e.status);
    }

    function getEscrowStatus(uint256 id) external view returns (Status) {
        return escrows[id].status;
    }
}
