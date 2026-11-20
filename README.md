# IE 498 · Exploring Smart Contracts

> **New: completed reference assignments (November 19, 2026).** See [illini-assignments/README.md](illini-assignments/README.md) for all nine assignments from `everythingapplejj/eth_testnet_experiment`, with their required interfaces, English report, and **84 passing tests**. Run that standalone project from its own directory. The original project and evidence described below are preserved separately.

This project implements all nine modules in the proposal submitted by Jiwoong Jung, Jiayan Guo, and Arjun Sahu on November 14, 2026. It uses Solidity 0.8.30, Foundry 1.4.4, ethers.js 6.15.0, and OpenZeppelin Contracts 5.4.0. The repository includes the educational implementation, reproducible tests, actual local-chain transaction evidence, and an experimental report.

## Quick start

Requirements: Node.js 20+, npm, and an internet connection for the initial installation. The setup script supports macOS (Apple Silicon requires Rosetta for the x86_64 Solidity compiler) and Linux x86_64.

Run these commands from the project directory:

```sh
npm ci
npm run setup
npm run verify
```

The setup script downloads the official Solidity compiler, verifies its SHA-256 checksum, and installs it in the project's `.tools/` directory. It does not install a global compiler. On other platforms, install a native Solidity 0.8.30 compiler and set `FOUNDRY_SOLC` to its absolute path. You can also use this variable to select an existing compiler. Foundry is provided through pinned npm packages; a global `forge` installation is not required.

```sh
npm run build          # Compile contracts
npm test               # 22 tests, including two fuzz tests with 256 runs each
npm run demo -- --watch # Show each transaction with a slower playback pace
npm run demo           # Start Anvil, deploy, demonstrate, verify, and shut down
npm run test:gas       # Generate a Foundry function-level gas report
npm run test:coverage  # Run the optional coverage check
```

The demo uses `127.0.0.1:18545` and chain ID `31337`; keep this port available. Each run creates four temporary wallets: Alice, Bob, Charlie, and Dana correspond to accounts 0, 1, 2, and 3. Transactions are signed through locally unlocked accounts; mnemonic phrases and private keys are neither saved nor printed. Each wallet starts with 1,000 ILT, and all Anvil ETH balances are simulated.

Addresses, transaction hashes, and gas values may vary between runs, while the workflow and final ILT balances remain consistent. The demo shuts down the chain when it finishes and preserves the evidence. A subsequent run overwrites `evidence/local/`.

## Contracts and business rules

All contract source code is in `src/Project.sol`. Each module is deployed as a separate contract.

| Module | Behavior and permissions |
|---|---|
| IlliniToken | Standard ERC-20 with 18 decimals; owner-only minting; holders can burn their tokens, and approved spenders can use `burnFrom`; supports `transfer`, `approve`, and `transferFrom`. |
| TokenFaucet | Prefunded distribution of 100 ILT per address every 24 hours. Insufficient faucet funds revert the transaction and roll back the cooldown update. |
| TokenVault | Deposits and withdrawals tracked in individual account ledgers. Users cannot withdraw another user's funds. |
| TokenSpender | Only the fixed operator, Bob, can spend an existing allowance. Approval requires trusting Bob to choose the recipient. |
| TokenMarketplace | Bob manages virtual products and prices. Each wallet may purchase each product once. Payment goes directly to Bob, and an on-chain purchase flag records the entitlement. |
| TokenEscrow | The buyer creates and funds a deal, then confirms payment before the deadline. The seller may refund an unsettled deal at any time; the buyer may refund it at or after the deadline. Finalized deals cannot be settled again. |
| TokenTimelock | Dana and the release timestamp are fixed at deployment. Anyone may trigger release after the deadline, but funds go only to Dana. |
| MultisigTreasury | Alice, Bob, and Charlie are three distinct owners. Two approvals allow any owner to execute a payment. Approvals can be revoked; duplicate approvals and repeated execution are rejected. |
| ApprovalSecurityLab | **Intentionally unsafe:** any caller can consume an allowance granted to this contract. Use only with disposable test tokens. |

Business contracts use SafeERC20 to handle token return values and apply reentrancy protection. The vault is designed for this project's ILT, not fee-on-transfer or rebasing tokens that change the amount actually received. Faucet limits apply per address, not per person. The token owner retains minting authority. Escrow cannot verify real-world delivery and does not provide dispute arbitration. These are explicit boundaries of the educational model.

## Evidence and reports

- `docs/REPORT.md`: methodology, measured results, requirements mapping, gas analysis, and limitations.
- `docs/transaction-replay.html`: browser-viewable replay of actual recorded transactions. Playback does not send new transactions.
- `docs/DEMO.md`: classroom demonstration steps and expected output.
- `docs/Project_Proposal_IE_498.pdf`: a copy of the original proposal.
- `evidence/tests.txt`, `evidence/build.txt`, and `evidence/gas-report.txt`: actual execution logs.
- `evidence/local/run.json`: deployment addresses, four wallets, stage snapshots, contract states, 47 successful transactions, and 8 expected failed transactions.
- `evidence/local/transactions.csv`: successful transaction receipts, including status, `gasUsed`, `gasPrice`, and `feeWei`.
- `evidence/local/failed-transactions.csv`: hashes and gas costs for expected reverted transactions.
- `evidence/npm-audit.json`: dependency audit results. The `ws` dependency is overridden to version 8.21.0 to address known dependency vulnerabilities.

Expected final balances are Alice: 865 ILT; Bob: 1,050 ILT; Charlie: 1,020 ILT; Dana: 1,410 ILT; Faucet: 800 ILT; and Treasury: 400 ILT. Total supply is 5,545 ILT. The Vault, Escrow, and Timelock balances are zero, and the lab allowance is zero.

## Optional Sepolia deployment

No Sepolia transactions were broadcast during the recorded experiment because testnet credentials were unavailable. See `evidence/sepolia-status.txt`. The deployment workflow is ready to run and requires no real funds or wallets holding real assets. Only free faucet-issued Sepolia ETH is needed to pay testnet gas fees.

Create a test-only encrypted JSON keystore on your computer. Set the following environment variables securely; do not commit their values to the repository or paste them into chat:

- `SEPOLIA_RPC_URL`: the Sepolia RPC endpoint.
- `SEPOLIA_KEYSTORE`: the path to Alice's encrypted keystore file.
- `KEYSTORE_PASSWORD`: supplied through a terminal prompt that does not echo input, or a password manager. The script does not print it.
- `BOB_ADDRESS`, `CHARLIE_ADDRESS`, and `DANA_ADDRESS`: public addresses of three other distinct test wallets. Their private keys are not required for deployment.

```sh
npm run deploy:sepolia
```

The script checks chain ID `11155111`, distinct nonzero wallet addresses, and the deployer's test ETH balance. It then deploys all nine contracts and mints tokens for the four wallets, faucet, treasury, and timelock.

Transaction evidence is saved in `evidence/sepolia/`. If deployment fails partway through, completed transaction receipts are saved in `evidence/sepolia-partial/`. Running the script again creates a new deployment. It does not purchase ETH or request private keys for wallets holding real funds.

Testnet time cannot be accelerated with `evm_increaseTime`: the 24-hour cooldown and timelock require waiting on Sepolia. The local demo's time-travel operations cannot be used on the public testnet.

## References

- [OpenZeppelin ERC-20 / SafeERC20](https://docs.openzeppelin.com/contracts/5.x/api/token/erc20)
- [Foundry official repository](https://github.com/foundry-rs/foundry)
- [ethers.js v6](https://docs.ethers.org/v6/)

This project is intended for coursework and has not undergone an independent security audit. ApprovalSecurityLab contains deliberate teaching vulnerabilities. Passing tests for the other contracts does not establish production security.
