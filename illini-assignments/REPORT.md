# IlliniToken Assignment Report

Validation date: November 19, 2026, America/Chicago. Test logs use UTC and therefore show November 20. This report covers only the standalone `illini-assignments` implementation.

## Objective and method

Implement the nine Solidity assignments described by [everythingapplejj/eth_testnet_experiment](https://github.com/everythingapplejj/eth_testnet_experiment), preserving their expected public function names and testing their functional requirements. The reference README contains historical deployment details and an outdated statement that all contracts are placeholders; this implementation uses its explicit assignment requirements as the specification, not its historical wallet addresses or completion claims.

The implementation uses Solidity 0.8.30, Cancun EVM, optimizer enabled with 200 runs, Foundry 1.4.4 and OpenZeppelin Contracts 5.4.0. Nine independent Foundry suites run in an isolated local EVM. Every test starts with a fresh one-million-ILT token and controlled accounts; Alice and Bob each receive 1,000 ILT from the initial supply. Remaining initial tokens stay with the test deployer. Some tests intentionally mint more tokens to verify minting or later-received-funds exposure.

## Verification results

Compilation succeeded. **84 automated tests passed; 0 failed; 0 skipped.** Suite counts: token 9, faucet 9, vault 10, spender 8, marketplace 9, escrow 11, timelock 9, treasury 11, approval lab 8. The vault conservation fuzz test exercised 256 inputs. The complete outputs are recorded in `evidence/verification.txt` and `evidence/gas-report.txt`.

The recorded output includes a harmless Foundry signature-cache warning because this execution environment disallows writing to the user's global cache. It does not affect compiler or test results. Logs are retained as emitted rather than edited to hide warnings.

Successful and unsuccessful transitions are tested directly: faucet cooldown and independent wallets; vault isolation and total liabilities; spender authorization and failed-payment rollback; marketplace stock, current prices and failed-payment rollback; escrow release/refund exclusion; independent timelocks; and two-owner treasury approval with duplicate and replay rejection. Event assertions cover all nine assignment suites. Standard ERC-20 transfer events and lab before/after observation fields are checked.

## Controlled approval observations

The following values come from assertions in `test/ApprovalSecurityLab.t.sol`. Amounts are whole ILT. Each row is an independent test, not a chronological sequence.

| Experiment | Allowance before | Attempt | Observed outcome |
|---|---:|---|---|
| Legitimate delegation | 50 | Alice initiates transfer of 50 to Bob | Succeeds; Alice 1,000 → 950, Bob 1,000 → 1,050; allowance 50 → 0. |
| Recipient redirection | 50 | Charlie initiates transfer of Alice's 50 to Dana | Succeeds without a new Alice transaction; Dana 0 → 50 and Alice 1,000 → 950. |
| Excess allowance | 50 | Attempt to move 51 | Reverts; Alice remains 1,000 and allowance remains 50. |
| Revocation | 50 → 0 | Attempt to transfer one base unit after revocation | Reverts. Revocation blocks later spending; it does not recover earlier transfers. |
| Limited exposure | 50 | Spend 50, then attempt one more base unit | First succeeds, second reverts; Dana receives exactly 50. |
| Unlimited exposure | uint256 maximum | Spend 1,000, receive 10 new tokens, then spend 10 | Both transfers succeed; Dana receives 1,010; unlimited allowance remains unchanged. |
| Insufficient balance | uint256 maximum | Attempt to spend 1,001 from a 1,000 balance | Reverts despite the unlimited allowance. |
| Observation event | 50 | Transfer 20 from Alice to Dana | Event reports allowance 50 → 30, Alice 1,000 → 980, Dana 0 → 20. |

An ERC-20 approval authorizes the spender contract, not a particular payment purpose or destination. A vulnerable spender can use `transferFrom` to choose a different recipient. OpenZeppelin's maximum allowance does not decrement, so later incoming funds remain exposed until revocation. The safer `TokenSpender` in Program 4 narrows its interface to payer-initiated transfers to a fixed payee. Exact allowances reduce exposure, but they do not make an unsafe spender trustworthy.

A reverted call rolls back its events as well as its state. Therefore failed attempts are documented by passing revert assertions, not by claiming persistent success events from reverted transactions. No public-chain transaction, mempool attack, or external wallet experiment was performed.

## Accounting and state rules

Token supply starts at 1,000,000 ILT. Transfers conserve supply; mint increases supply; burn decreases it. The vault maintains a separate ledger and total liability count; unsolicited transfers can make assets exceed liabilities, but cannot grant a caller withdrawal rights. Failed transfers roll back ledger, stock, settlement and execution flags atomically.

At the escrow deadline the buyer may refund but may no longer release. At a timelock's unlock timestamp its beneficiary may withdraw. At exactly 24 hours a faucet claimant becomes eligible again. These boundaries are exercised without real waiting through Foundry time controls. Sepolia would require real elapsed time.

Treasury proposals start with zero approvals. Only distinct owners contribute to the threshold. An underfunded execution reverts and remains unexecuted, allowing funding and a later retry. No owner rotation or arbitrary contract-call execution is included.

## Gas and limitations

The gas report contains Foundry's measured deployment and function-call gas under the configured local EVM. Test-function gas values also include test setup actions inside those test bodies; they must not be presented as standalone transaction receipt fees. No ETH or dollar costs are inferred from these measurements.

Tests provide concrete regression evidence, not proof of security or formal verification. The lab is intentionally vulnerable. Other contracts assume the project's ordinary ILT, not arbitrary fee-on-transfer or rebasing tokens. Faucet limits do not stop multiple identities, marketplace events do not prove off-chain delivery, and escrow cannot arbitrate disputes. The administrator can mint new ILT. Production security review and public-testnet deployment are outside these recorded results.

## Reproduction and provenance

Run `npm ci`, `npm run setup`, and `npm run verify` from this directory. For gas measurements run `node scripts/forge.mjs test --gas-report`. The lockfile pins dependencies; the setup script validates the compiler checksum against its official manifest. No private keys or API credentials are included.

The reference assignment is credited above. The nine contracts and tests in this directory were implemented for this submission. Existing root-level project evidence belongs to an earlier implementation and is not evidence for this one.
