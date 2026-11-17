# IE 498 — Exploring Smart Contracts: Experimental Report

Implementation and experiment date: 2026-11-17T22:19:09.705Z. This report records an automated implementation of the supplied November 14, 2026 proposal by Jiwoong Jung, Jiayan Guo and Arjun Sahu. It does not attribute authorship of the generated code or observations to those students. All reported transactions are from a disposable Anvil chain, not Sepolia.

## 1. Research question and experimental design

How can Solidity implement decentralized financial operations, and what technical/security challenges arise? We implemented nine separately deployed contracts around an ERC-20 token, and exercised authorized and unauthorized actions with Alice, Bob, Charlie and Dana. The methodology combines Solidity unit/fuzz tests with ethers.js integration transactions on an actual local EVM node. Each integration receipt records status, gas, hash and logs. Balance snapshots record both ETH and ILT; contract-state queries verify terminal outcomes.

Environment: Solidity 0.8.30, Cancun EVM, optimizer enabled with 200 runs, Foundry/Anvil 1.4.4, ethers.js 6.15.0, OpenZeppelin Contracts 5.4.0. Dependencies are pinned in package-lock.json. The local chain has ID 31337; a fresh random mnemonic is discarded after each experiment. Transactions are signed through local unlocked accounts. No private key appears in the deliverable.

The proposal lists nine modules. Its later general reference to a “loaning system” has no separate specified lending module; this implementation follows the nine explicit bullets. Sepolia deployment is prepared but unexecuted because the required RPC and encrypted test keystore credentials were unavailable. No public-network results are claimed.

## 2. Requirements and verification mapping

| Proposal module | Implementation and tested result |
|---|---|
| IlliniToken | Owner-controlled mint, ERC20 transfer/allowance, burn and burnFrom. Unauthorized mint, zero-address and insufficient-balance transfers revert; fuzz transfer preserves supply. |
| TokenFaucet | 100 ILT/address/24 hours; first claim succeeds, one second before expiry rejects, exact expiry succeeds. An unfunded faucet rolls back the cooldown. |
| TokenVault | Per-address ledger and total liabilities. Other-user and excessive withdrawals reject; full withdrawal restores funds. Fuzz deposits/withdrawals conserve assets and liabilities. |
| TokenSpender | Bob is the fixed operator; transferFrom consumes Alice’s allowance. Unauthorized operators and exhausted allowances reject. |
| TokenMarketplace | Merchant-only product configuration, fixed current price, single purchase per product/address. Unknown and repeated products reject; failed payment rolls back entitlement. |
| TokenEscrow | Buyer confirmation pays seller before deadline. Seller may refund early; buyer may refund at/after deadline. Unauthorized/repeated settlements reject. |
| TokenTimelock | Immutable Dana beneficiary; before-deadline release fails, exact deadline succeeds. Any caller can trigger transfer only to the beneficiary. |
| MultisigTreasury | Three unique nonzero owners; two approvals required. Duplicate approvals, outsider approval, one-vote execution and replay reject. Revocation removes a vote. |
| ApprovalSecurityLab | Deliberately unrestricted transferFrom demonstrates malicious spender, unlimited approval persistence, overwrite race, bounded allowance loss, and revocation limits. |

## 3. Test outcomes and evidence

Build succeeded. **22 Solidity tests passed, 0 failed, 0 skipped**. Two fuzz tests each ran 256 inputs. The integration demo produced **47 successful transactions and 8 expected mined reverts**. Revert receipts have status 0 and still incur gas. All stage snapshots passed total-supply reconciliation, and final wallet balances were asserted by the script.

Foundry coverage reported 100/100 lines, 81/81 statements, 22/22 functions and 35/44 branches (79.55%) for src/Project.sol. Coverage is an auxiliary metric: Foundry 1.4.4 emitted source-map anchor warnings with this compiler during the initial coverage run; the recorded clean summary suppresses logging noise. These metrics are not proof of complete path coverage or security. Missing branches include some constructor/invalid-parameter paths. No formal verification or independent audit was performed.

Primary evidence: evidence/tests.txt, build.txt, verification.txt, gas-report.txt, coverage.txt, local/run.json, local/transactions.csv and local/failed-transactions.csv. The JSON includes raw event topics/data; ABIs can be regenerated with npm run build. npm audit reported zero known dependency vulnerabilities after pinning ws 8.21.0; this is not a contract audit.

## 4. Wallets and state reconciliation

| Wallet | Public address in recorded run | Initial ILT | Final ILT |
|---|---|---:|---:|
| Alice | 0xC158f0B860b8954b8F78245ef0355831ec410bD1 | 1000 | 865.0 |
| Bob | 0x187b15141E61c6d950A9BC136ee3739489B1CF48 | 1000 | 1050.0 |
| Charlie | 0x66cDf25cff05c06469e50D4C9b74A9861A4FE77d | 1000 | 1020.0 |
| Dana | 0x80fe77e3D9e41b0CC3649350C6f58dC3DEb3fbF4 | 1000 | 1410.0 |

Alice received 200 faucet ILT; transferred 10 to Bob, 20 to Charlie, 15 for a product and 30 through confirmed escrow; the security experiments transferred 260 to Dana. Vault and refunded escrow operations net to zero. Bob received 55 and burned 5. Charlie received 20. Dana received 100 from treasury, 50 from timelock and 260 from security experiments.

The faucet retains 800 and treasury 400 ILT. Wallets sum to 4345; contracts hold 1200, totaling **5545 ILT**, equal to 5550 minted less 5 burned. Vault liabilities and assets are zero. Both escrow deals are terminal: Released (1), Refunded (2). The purchased entitlement is true; treasury execution is true; lab allowance is zero. Timelock balance is zero.

## 5. Gas observations

These are receipt gas values from this run, including intrinsic transaction gas. They are not the gas figures for entire Foundry test functions. ETH fees equal gasUsed × effective gasPrice; local base fees vary per block and must not be interpreted as Sepolia prices or dollar costs.

| Transaction | Gas used | Fee (wei) |
|---|---:|---:|
| token:transfer | 34491 | 4235417402196 |
| token:burn | 33869 | 3640352971508 |
| faucet:claim | 63196 | 5945369213392 |
| vault:deposit | 103705 | 6544617628920 |
| vault:withdraw | 43569 | 2107783609002 |
| spender:spend | 43473 | 1410516654657 |
| market:buy | 69293 | 1508460035607 |
| escrow:create-confirm | 179033 | 2987253331170 |
| escrow:confirm | 69579 | 1017571862142 |
| multisig:approve-A | 74401 | 640016225453 |
| multisig:approve-B | 57301 | 377784576184 |
| multisig:execute | 73898 | 426539994980 |
| escrow:timeout-refund | 69681 | 269699683371 |
| timelock:release | 36669 | 124268600832 |
| faucet:next-day | 46096 | 136736777408 |
| lab:malicious-drain | 40217 | 91417986606 |
| lab:revoke | 24417 | 48583505997 |

Successful transactions consumed 6,008,390 gas including nine deployments; expected reverts consumed 239,366 gas. Total simulated ETH fee was 0.002525253747581885 ETH. First faucet claims and first multisig approvals cost more than subsequent ones because of storage transitions. Escrow creation writes several persistent fields and transfers funds, so costs more than a basic transfer. Vault withdrawal clears storage and its accounting; comparisons depend on the precise state and refund rules, not just contract names.

## 6. Approval security findings

1. **Unlimited allowance:** approval of uint256.max lets the lab transfer funds to any caller. OpenZeppelin preserves MAX allowance rather than decrementing it. A unit test also mints new victim funds after the initial drain and shows those are still exposed.
2. **Allowance overwrite race:** the experiment orders transactions as attacker spends old 100, owner sets new 50, attacker spends 50. Loss is 150, rather than the intended new limit of 50. This is deterministic transaction-order simulation, not a measurement of real mempool front-running.
3. **Revocation:** approve(spender, 0) blocks subsequent drains once mined. It cannot recover spent tokens or prevent transactions ordered before revocation. Zero-first plus confirmation must include checking actual prior spending before granting a new amount.
4. **Exact allowance:** approval of 10 caps this experiment’s loss at 10 and a subsequent drain rejects. It limits exposure but does not make a malicious spender trustworthy.
5. **Delegated authority:** a normal TokenSpender restricts callers to Bob, but Alice must still trust Bob’s choice of payee and amount within the allowance. ERC-20 approval alone does not encode purchase intent.

The vulnerable lab is explicitly labeled and isolated. No attacks against external wallets or networks were performed.

## 7. Design limits and conclusions

OpenZeppelin supplies the ERC-20 mechanics. SafeERC20 handles token return values; business contracts use reentrancy guards and settle bookkeeping atomically. The vault assumes the project’s non-rebasing, fee-free ILT. It is not a generic token vault. Faucet anti-abuse is address-based and does not prevent Sybil identities. Token minting remains centralized under the owner. Marketplace entitlement is a chain record, not off-chain content delivery. Escrow cannot determine factual delivery and has no arbitrator; its timeout refund policy is a deliberate classroom simplification. The treasury has fixed owners and threshold, no owner rotation, expiry or emergency recovery.

Local time travel tests boundary behavior quickly; on Sepolia the real 24-hour wait is necessary. The optional script checks Sepolia chain ID, distinct test addresses and test ETH balance, and uses an encrypted keystore without logging secrets. It preserves partial receipts on failure. Only that public-network deployment remains unexecuted, owing to unavailable credentials.

The results demonstrate that financial workflow rules can be enforced as explicit state transitions, while permission scope, transaction order, trust in administrators and external delivery remain essential design concerns. This is a working educational prototype rather than a production financial system.

## References

- Supplied Project Proposal (Exploring Smart Contracts), November 14, 2026, reproduced in docs/Project_Proposal_IE_498.pdf.
- OpenZeppelin ERC-20/SafeERC20: https://docs.openzeppelin.com/contracts/5.x/api/token/erc20
- Foundry official project: https://github.com/foundry-rs/foundry
- ethers.js v6: https://docs.ethers.org/v6/
