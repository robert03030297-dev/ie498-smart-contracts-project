# IlliniToken — Nine Completed Solidity Assignments

This standalone coursework implementation follows the nine programming assignments in [eth_testnet_experiment](https://github.com/everythingapplejj/eth_testnet_experiment#illinitoken-solidity-programming-assignments), inspected on November 19, 2026 (America/Chicago). It is maintained in **robert03030297-dev/ie498-smart-contracts-project**. All code, documentation, and test descriptions are in English.

**Verified result: 84 tests passed, zero failed, zero skipped across nine suites.** The vault fuzz test runs 256 inputs. See [the actual build and test log](evidence/verification.txt), [gas report](evidence/gas-report.txt), and [experimental report](REPORT.md).

This directory is independent of the earlier project at the repository root. That project's sources, reports, demo, and archive remain historical artifacts with different interfaces and rules. Run the following commands **inside `illini-assignments`** to reproduce this submission.

## Run

Requirements: Node.js 20+, npm, and internet access for installation. The included compiler installer supports macOS (Apple Silicon requires Rosetta for the official x86_64 compiler) and Linux x86_64. On other platforms, provide Solidity 0.8.30 through `FOUNDRY_SOLC`.

```sh
cd illini-assignments
npm ci
npm run setup
npm run verify
```

The setup script downloads the official Solidity 0.8.30 compiler, checks its SHA-256 digest against the official manifest, and saves it locally in `.tools/`. Foundry 1.4.4 and OpenZeppelin 5.4.0 are pinned through npm. No global Foundry installation, wallet credentials, faucet funds, or public RPC is required for tests.

```sh
npm run sol:build
npm run sol:test
node scripts/forge.mjs test --match-contract TokenEscrowTest -vvvv
node scripts/forge.mjs test --gas-report
```

## Assignment completion

| Done | Program / source | Tests | Implemented behavior |
|---|---|---:|---|
| [x] | [IlliniToken](contracts/IlliniToken.sol) | 9 | 1,000,000 ILT minted to deployer; 18 decimals; owner mint; holder burn; ERC-20 transfers and approvals. |
| [x] | [TokenFaucet](contracts/TokenFaucet.sol) | 9 | 100 ILT per address per 24 hours, approval-based deposits, remaining-time and balance queries. |
| [x] | [TokenVault](contracts/TokenVault.sol) | 10 | Per-user deposits, partial/full withdrawals, total liabilities, accounting events and fuzz conservation. |
| [x] | [TokenSpender](contracts/TokenSpender.sol) | 8 | Payer-initiated payments to an immutable payee, payment totals, allowance/balance queries. |
| [x] | [TokenMarketplace](contracts/TokenMarketplace.sol) | 9 | Named products, unique IDs, prices, stock, owner-only administration and allowance-based purchases. |
| [x] | [TokenEscrow](contracts/TokenEscrow.sol) | 11 | Buyer-funded deals, buyer confirmation before deadline, buyer refund at/after deadline, single settlement. |
| [x] | [TokenTimelock](contracts/TokenTimelock.sol) | 9 | Multiple independent locks, depositor/beneficiary metadata, beneficiary-only withdrawals at/after unlock. |
| [x] | [MultiSigTreasury](contracts/MultiSigTreasury.sol) | 11 | Three distinct nonzero owners, two explicit approvals, owner-only proposal/approval/execution, replay prevention. |
| [x] | [ApprovalSecurityLab](contracts/ApprovalSecurityLab.sol) | 8 | Controlled delegated-transfer, redirection, revocation, limited/unlimited allowance and event observations. |

Each module has at least five tests including negative cases; relevant suites test access control, balances, time boundaries, rollback, and events. All expected function names from the reference assignment are implemented. Shared token validation and reentrancy protection live in `contracts/TokenApp.sol`.

## Explicit design decisions

- **Spender:** only `from` may call `spendTokens(from, amount)`. Payment goes to the immutable constructor payee. Granting allowance alone does not let outsiders initiate a payment through this contract.
- **Marketplace:** the deployer is the permanent owner and receives payments. A purchase reduces stock by one; repeated purchases are allowed while stock remains. Product IDs start at zero; invalid IDs revert. No physical delivery is modeled.
- **Escrow:** only the buyer may settle. Confirmation is allowed strictly before `deadline`; refund is allowed at or after it. A seller cannot confirm or refund. Settled deals cannot transition again. This is a deadline policy, not a dispute arbitration service.
- **Timelock:** each lock has an independent zero-based ID. Only its beneficiary may withdraw, including at the exact unlock timestamp. The depositor has no cancellation privilege.
- **Treasury:** proposing does not count as approval. Two distinct owners must explicitly approve; only an owner may execute. Owners and threshold are fixed.
- **Token:** mint authority is permanently assigned to the deployer. Supply is initially one million ILT but is not capped; mint and burn update it normally.
- **Faucet:** an explicit first-request flag permits a first claim even at timestamp zero without allowing a second immediate claim. The limit is per address, not per person.
- **Vault:** intended for this project's fee-free, non-rebasing ILT. Direct donations add assets but create no user deposit credit; liabilities remain less than or equal to assets.

`SafeERC20` reverts failed transfers and the EVM rolls back bookkeeping. Custody functions use checks-effects-interactions and reentrancy protection. Constructor token addresses must contain deployed code. Token code existence is not a guarantee of ERC-20 compatibility.

## Experimental scope

All observed results are from Foundry's local EVM using developer-controlled test addresses A–D. The optional Sepolia deployment mentioned in the assignment was **not performed**; no new public-network deployment or transaction hashes are claimed. This submission requires no interaction with the reference author's wallets or contracts.

The lab is deliberately unsafe: any caller can redirect tokens approved to it. Only disposable educational tokens should be approved. These contracts are coursework, not audited production contracts. See [REPORT.md](REPORT.md) for measured allowance outcomes and limitations.
