// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./TokenApp.sol";

contract MultiSigTreasury is TokenApp {
    using SafeERC20 for IERC20;
    mapping(address => bool) public isOwner;
    mapping(uint256 => mapping(address => bool)) public approved;

    struct Proposal {
        address to;
        uint256 amount;
        uint256 approvals;
        bool executed;
    }
    Proposal[] public proposals;
    event Proposed(uint256 indexed id, address indexed to, uint256 amount);
    event Approved(uint256 indexed id, address indexed owner);
    event Executed(uint256 indexed id);
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Only owner");
        _;
    }

    constructor(IERC20 t, address[3] memory owners) TokenApp(t) {
        for (uint256 i; i < 3; i++) {
            require(owners[i] != address(0) && !isOwner[owners[i]], "Invalid owners");
            isOwner[owners[i]] = true;
        }
    }

    /// @notice Proposing does not automatically approve.
    function proposeTransfer(address to, uint256 amount) external onlyOwner returns (uint256 id) {
        require(to != address(0) && amount > 0, "Invalid transfer");
        id = proposals.length;
        proposals.push(Proposal(to, amount, 0, false));
        emit Proposed(id, to, amount);
    }

    function approveTransfer(uint256 id) external onlyOwner {
        Proposal storage p = proposals[id];
        require(!p.executed && !approved[id][msg.sender], "Invalid approval");
        approved[id][msg.sender] = true;
        p.approvals++;
        emit Approved(id, msg.sender);
    }

    function executeTransfer(uint256 id) external onlyOwner nonReentrant {
        Proposal storage p = proposals[id];
        require(!p.executed && p.approvals >= 2, "Not executable");
        p.executed = true;
        token.safeTransfer(p.to, p.amount);
        emit Executed(id);
    }

    function getApprovalCount(uint256 id) external view returns (uint256) {
        return proposals[id].approvals;
    }
}
