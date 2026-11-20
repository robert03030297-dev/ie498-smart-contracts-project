// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./TokenApp.sol";

/// @notice INTENTIONALLY UNSAFE: any caller may use allowances granted to this lab.
/// Use only disposable ILT and developer-controlled local/testnet accounts.
contract ApprovalSecurityLab is TokenApp {
    using SafeERC20 for IERC20;
    event Observation(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 allowanceBefore,
        uint256 allowanceAfter,
        uint256 balanceBefore,
        uint256 balanceAfter,
        uint256 recipientBefore,
        uint256 recipientAfter
    );
    constructor(IERC20 t) TokenApp(t) {}

    function executeApprovedTransfer(address from, address to, uint256 amount) external nonReentrant {
        uint256 allowanceBefore = checkAllowance(from);
        uint256 balanceBefore = token.balanceOf(from);
        uint256 recipientBefore = token.balanceOf(to);
        token.safeTransferFrom(from, to, amount);
        emit Observation(
            from,
            to,
            amount,
            allowanceBefore,
            checkAllowance(from),
            balanceBefore,
            token.balanceOf(from),
            recipientBefore,
            token.balanceOf(to)
        );
    }

    function checkAllowance(address user) public view returns (uint256) {
        return token.allowance(user, address(this));
    }
}
