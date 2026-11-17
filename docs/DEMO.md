# 8 分钟课堂演示

1. **准备（1 分钟）**：打开 README，介绍九项模块和四钱包。首次执行 `npm ci && npm run setup`，展示 `npm test` 的 22 项通过结果。
2. **运行（1 分钟）**：执行 `npm run demo`。会自动部署全部模块，在本地执行交易并推进 24 小时，无需钱包插件或资金。
3. **核心流程（2 分钟）**：打开 `evidence/local/transactions.csv`，依次定位 faucet、vault、spender、market、escrow、multisig 和 timelock 标签。用 run.json 的 snapshots 比较初始与结束余额；vault-funded 快照展示存款期间资产和负债一致。
4. **失败也是证据（1 分钟）**：打开 failed-transactions.csv。解释 status 0 交易不会转移 ILT，但仍消耗 gas。展示冷却期、他人提款、单人多签和提前解锁的拒绝。
5. **授权实验（2 分钟）**：展示 unlimited-approval 后 malicious-drain，解释 MAX allowance 不递减；revoke 后 drain 回滚。对比旧额度 100 被先花费、覆盖为 50 后再花费，总损失 150。最后展示 exact-allowance 限制为 10。撤销不能追回已转出的资产；先归零并确认也不能消除归零交易之前的抢跑损失，必须复核实际余额/支出。
6. **结论（1 分钟）**：核对最终四钱包 865 / 1050 / 1020 / 1410 ILT，总供应 5545；演示 Sepolia 脚本无凭证时明确 SKIPPED。说明本次结果来自 Anvil，而非测试网。

演示完全可重复，但临时地址、交易哈希随运行改变。Anvil 在演示结束退出，交易可通过已保存 receipt 数据查看，不能在公共区块浏览器查询。

## 可视过程模式

在 macOS Finder 中双击项目的 `run-demo.command`，会自动检查依赖、执行测试并逐笔显示演示。也可在项目终端执行 `npm run demo -- --watch`。每步显示 status、gas、区块和交易哈希；预期回滚明确标注为安全拦截。最后列出四钱包余额。此模式执行真实本地交易，不是历史动画回放。
