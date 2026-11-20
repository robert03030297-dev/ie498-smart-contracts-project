// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract TokenApp is ReentrancyGuard {
    IERC20 public immutable token;

    constructor(IERC20 t) {
        require(address(t).code.length > 0, "Invalid token");
        token = t;
    }
}
