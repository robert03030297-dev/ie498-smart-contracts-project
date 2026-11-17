// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract IlliniToken is ERC20, ERC20Burnable, Ownable {
    constructor(address admin) ERC20("IlliniToken", "ILT") Ownable(admin) {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

abstract contract TokenApp is ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;

    constructor(IERC20 t) {
        require(address(t).code.length > 0, "token");
        token = t;
    }
}

contract TokenFaucet is TokenApp {
    using SafeERC20 for IERC20;
    uint256 public constant AMOUNT = 100 ether;
    uint256 public constant COOLDOWN = 1 days;
    mapping(address => uint256) public nextClaim;
    event Claimed(address indexed user, uint256 amount);
    constructor(IERC20 t) TokenApp(t) {}

    function claim() external nonReentrant {
        require(block.timestamp >= nextClaim[msg.sender], "cooldown");
        nextClaim[msg.sender] = block.timestamp + COOLDOWN;
        token.safeTransfer(msg.sender, AMOUNT);
        emit Claimed(msg.sender, AMOUNT);
    }
}

contract TokenVault is TokenApp {
    using SafeERC20 for IERC20;
    mapping(address => uint256) public deposits;
    uint256 public totalDeposits;
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    constructor(IERC20 t) TokenApp(t) {}

    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "zero");
        token.safeTransferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;
        totalDeposits += amount;
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0 && deposits[msg.sender] >= amount, "balance");
        deposits[msg.sender] -= amount;
        totalDeposits -= amount;
        token.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
}

contract TokenSpender is TokenApp {
    using SafeERC20 for IERC20;
    address public immutable operator;
    event Spent(address indexed from, address indexed to, uint256 amount);

    constructor(IERC20 t, address op) TokenApp(t) {
        require(op != address(0), "operator");
        operator = op;
    }

    function spend(address from, address to, uint256 amount) external nonReentrant {
        require(msg.sender == operator, "operator");
        require(amount > 0, "zero");
        token.safeTransferFrom(from, to, amount);
        emit Spent(from, to, amount);
    }
}

contract TokenMarketplace is TokenApp, Ownable {
    using SafeERC20 for IERC20;

    struct Product {
        uint256 price;
        bool active;
    }
    mapping(uint256 => Product) public products;
    mapping(address => mapping(uint256 => bool)) public purchased;
    address public immutable merchant;
    event ProductSet(uint256 indexed id, uint256 price, bool active);
    event Purchased(address indexed buyer, uint256 indexed id, uint256 price);

    constructor(IERC20 t, address seller) TokenApp(t) Ownable(seller) {
        merchant = seller;
    }

    function setProduct(uint256 id, uint256 price, bool active) external onlyOwner {
        require(price > 0, "price");
        products[id] = Product(price, active);
        emit ProductSet(id, price, active);
    }

    function buy(uint256 id) external nonReentrant {
        Product memory p = products[id];
        require(p.active && !purchased[msg.sender][id], "product");
        purchased[msg.sender][id] = true;
        token.safeTransferFrom(msg.sender, merchant, p.price);
        emit Purchased(msg.sender, id, p.price);
    }
}

contract TokenEscrow is TokenApp {
    using SafeERC20 for IERC20;
    enum State {
        Funded,
        Released,
        Refunded
    }

    struct Deal {
        address buyer;
        address seller;
        uint256 amount;
        uint256 deadline;
        State state;
    }
    Deal[] public deals;
    event Created(uint256 indexed id, address indexed buyer, address indexed seller, uint256 amount, uint256 deadline);
    event Settled(uint256 indexed id, State state);
    constructor(IERC20 t) TokenApp(t) {}

    function create(address seller, uint256 amount, uint256 deadline) external nonReentrant returns (uint256 id) {
        require(seller != address(0) && seller != msg.sender && amount > 0 && deadline > block.timestamp, "deal");
        id = deals.length;
        deals.push(Deal(msg.sender, seller, amount, deadline, State.Funded));
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Created(id, msg.sender, seller, amount, deadline);
    }

    function confirm(uint256 id) external nonReentrant {
        Deal storage d = deals[id];
        require(msg.sender == d.buyer && d.state == State.Funded && block.timestamp < d.deadline, "confirm");
        d.state = State.Released;
        token.safeTransfer(d.seller, d.amount);
        emit Settled(id, d.state);
    }

    function refund(uint256 id) external nonReentrant {
        Deal storage d = deals[id];
        require(d.state == State.Funded, "settled");
        require(msg.sender == d.seller || (msg.sender == d.buyer && block.timestamp >= d.deadline), "refund");
        d.state = State.Refunded;
        token.safeTransfer(d.buyer, d.amount);
        emit Settled(id, d.state);
    }
}

contract TokenTimelock is TokenApp {
    using SafeERC20 for IERC20;
    address public immutable beneficiary;
    uint256 public immutable releaseTime;
    event Released(uint256 amount);

    constructor(IERC20 t, address to, uint256 when) TokenApp(t) {
        require(to != address(0) && when > block.timestamp, "lock");
        beneficiary = to;
        releaseTime = when;
    }

    function release() external nonReentrant {
        require(block.timestamp >= releaseTime, "locked");
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "empty");
        token.safeTransfer(beneficiary, amount);
        emit Released(amount);
    }
}

contract MultisigTreasury is TokenApp {
    using SafeERC20 for IERC20;
    mapping(address => bool) public isOwner;

    struct Payment {
        address to;
        uint256 amount;
        uint256 approvals;
        bool executed;
    }
    Payment[] public payments;
    mapping(uint256 => mapping(address => bool)) public approved;
    event Proposed(uint256 indexed id, address to, uint256 amount);
    event Approved(uint256 indexed id, address indexed owner);
    event Revoked(uint256 indexed id, address indexed owner);
    event Executed(uint256 indexed id);
    modifier onlyOwner() {
        require(isOwner[msg.sender], "owner");
        _;
    }

    constructor(IERC20 t, address[3] memory owners) TokenApp(t) {
        for (uint256 i; i < 3; i++) {
            require(owners[i] != address(0) && !isOwner[owners[i]], "owners");
            isOwner[owners[i]] = true;
        }
    }

    function propose(address to, uint256 amount) external onlyOwner returns (uint256 id) {
        require(to != address(0) && amount > 0, "payment");
        id = payments.length;
        payments.push(Payment(to, amount, 0, false));
        emit Proposed(id, to, amount);
    }

    function approve(uint256 id) external onlyOwner {
        require(!payments[id].executed && !approved[id][msg.sender], "approval");
        approved[id][msg.sender] = true;
        payments[id].approvals++;
        emit Approved(id, msg.sender);
    }

    function revoke(uint256 id) external onlyOwner {
        require(!payments[id].executed && approved[id][msg.sender], "approval");
        approved[id][msg.sender] = false;
        payments[id].approvals--;
        emit Revoked(id, msg.sender);
    }

    function execute(uint256 id) external nonReentrant onlyOwner {
        Payment storage p = payments[id];
        require(!p.executed && p.approvals >= 2, "quorum");
        p.executed = true;
        token.safeTransfer(p.to, p.amount);
        emit Executed(id);
    }
}

/// @notice INTENTIONALLY UNSAFE lab: any caller can consume an approval to this contract.
/// Never approve this contract outside disposable experiments.
contract ApprovalSecurityLab is TokenApp {
    using SafeERC20 for IERC20;
    constructor(IERC20 t) TokenApp(t) {}

    function drain(address victim, uint256 amount) external {
        token.safeTransferFrom(victim, msg.sender, amount);
    }
}
