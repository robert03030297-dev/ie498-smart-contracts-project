# Eight-Minute Classroom Demonstration

1. **Preparation (1 minute):** Open the README and introduce the nine modules and four wallets. Before the first demonstration, run `npm ci && npm run setup`. Show the 22 passing tests produced by `npm test`.
2. **Run the demo (1 minute):** Execute `npm run demo`. It automatically deploys every module, executes local transactions, and advances the local chain clock by 24 hours. No wallet extension or real funds are required.
3. **Core workflows (2 minutes):** Open `evidence/local/transactions.csv` and locate the faucet, vault, spender, market, escrow, multisig, and timelock labels. Compare initial and final balances using the `snapshots` in `evidence/local/run.json`. The `vault-funded` snapshot shows that vault assets match its deposit liabilities while funds are held.
4. **Failures are evidence too (1 minute):** Open `evidence/local/failed-transactions.csv`. Explain that transactions with status `0` revert their ILT transfers but still consume gas. Show the rejected attempts to claim during the cooldown, withdraw another user's funds, execute a multisig payment with only one approval, and release locked funds early.
5. **Approval security experiments (2 minutes):** Show `unlimited-approval` followed by `malicious-drain`, and explain why the maximum allowance does not decrease. Show that a drain after `revoke` reverts. Next, demonstrate the allowance overwrite race: an attacker spends the old allowance of 100 ILT, the owner replaces it with 50 ILT, and the attacker spends another 50 ILT, for a total loss of 150 ILT. Finally, show how `exact-allowance` limits the amount to 10 ILT. Revocation cannot recover tokens already transferred. Setting the allowance to zero and waiting for confirmation also cannot prevent losses from transactions ordered before revocation; actual balances and prior spending must be checked before granting a new allowance.
6. **Conclusion (1 minute):** Verify final wallet balances of 865 / 1050 / 1020 / 1410 ILT for Alice / Bob / Charlie / Dana, and a total supply of 5545 ILT. Run `npm run deploy:sepolia` without credentials to demonstrate the explicit `SKIPPED` result. State that the recorded results come from Anvil, not a public testnet.

The demonstration is reproducible, although temporary addresses and transaction hashes change between runs. Anvil shuts down when the demo ends. Transactions can be inspected through the saved receipt data but cannot be looked up on a public block explorer.

## Step-by-Step Terminal Mode

On macOS, double-click `run-demo.command` in Finder to check dependencies, run the tests, and display the demonstration transaction by transaction. If the downloaded file is not executable, run `chmod +x run-demo.command` from the project directory first, or launch it with `zsh run-demo.command`.

Alternatively, run this command from the project directory:

```sh
npm run demo -- --watch
```

Each step displays the transaction status, gas used, block number, and transaction hash. Expected reverts are explicitly identified as successful security checks. The final output lists the balances of all four wallets. This mode executes actual local-chain transactions; it is not a replay of historical results.

For a replay of the saved experiment without starting a blockchain node, open `docs/transaction-replay.html` in a browser. That page does not send new transactions.
