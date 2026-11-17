# IE 498 · Exploring Smart Contracts

根据 Jiwoong Jung、Jiayan Guo、Arjun Sahu 于 2026-11-14 提交的 proposal 实现全部九项模块。Solidity 0.8.30 / Foundry 1.4.4 / ethers.js 6.15.0 / OpenZeppelin 5.4.0。此交付包含课程实验代码、可重复运行的测试、真实本地链交易证据和报告。

## 一键验证

需要 Node.js 20+、npm、首次安装时的网络连接。macOS（Apple Silicon 需要 Rosetta 支持 x86_64 solc）或 Linux x86_64：

```sh
npm ci
npm run setup
npm run verify
```

在项目目录运行。setup 将校验 SHA-256 的官方 solc 安装到项目 `.tools/`，不会安装到全局。其他平台可安装原生 Solidity 0.8.30 后设置 `FOUNDRY_SOLC` 为编译器绝对路径。Foundry 通过锁定的 npm 包提供，不需要全局 forge。若已有编译器，也可直接使用 `FOUNDRY_SOLC`。

```sh
npm run build          # 编译
npm test               # 22 项测试；两个 fuzz 测试各 256 次
npm run demo -- --watch # 逐笔显示交易过程（放慢播放）
npm run demo           # 自动启动临时 Anvil、部署、演示、校验、关闭
npm run test:gas       # Foundry 函数级 gas 报告
npm run test:coverage  # 可选覆盖率检查
```

演示使用 127.0.0.1:18545 / chain ID 31337，请保持端口空闲。每次生成临时四钱包，Alice/Bob/Charlie/Dana 对应账户 0/1/2/3；只通过本地解锁账户签名，不保存或打印助记词与私钥。每人初始 1000 ILT，Anvil ETH 为虚拟余额。每次运行的地址、哈希和 gas 可能不同；流程和最终 ILT 余额保持一致。演示结束关闭链，保留证据；下一次运行会覆盖 evidence/local/。

## 合约和业务规则

全部源码在 `src/Project.sol`，每个模块都是独立部署的合约。

| 模块 | 行为与权限 |
|---|---|
| IlliniToken | 标准 18 位 ERC-20；owner mint；本人 burn / 授权 burnFrom；transfer / approve / transferFrom |
| TokenFaucet | 预先充值；每地址每 24 小时 100 ILT；余额不足回滚冷却状态 |
| TokenVault | 个人账本存取款；不可提取他人的资金 |
| TokenSpender | 仅固定 operator（Bob）可按已有 allowance 代扣；授权意味着信任 Bob 可选择收款人 |
| TokenMarketplace | Bob 管理虚拟商品及定价；每钱包每商品一次；付款直接给 Bob；链上购买标记作为权益凭证 |
| TokenEscrow | 买家创建并付款；到期前买家确认付款；卖家随时退款；到期后买家退款；最终状态不可重放 |
| TokenTimelock | 部署时固定 Dana 与释放时间；到期任何人可触发，但只转给 Dana |
| MultisigTreasury | Alice/Bob/Charlie 三个不同 owner；2 人批准后任一 owner 执行；可撤销批准；防重复批准/执行 |
| ApprovalSecurityLab | **故意不安全**：任意调用者可消耗对实验合约的授权。仅用于临时测试代币 |

业务合约通过 SafeERC20 处理返回值并采用重入保护。Vault 仅面向本项目 ILT，不支持扣税、rebase 等改变实际到账量的代币。Faucet 为每地址限流，不是每个人限流；代币管理员有增发权。Escrow 不判断现实世界交付，也没有争议仲裁。以上是课程模型的明确边界。

## 证据与报告

- `docs/REPORT.md`：实验方法、实测结果、九项映射、gas 分析及局限。
- `docs/transaction-replay.html`：可在浏览器打开的真实交易回放；点击播放，不发送新交易。
- `docs/DEMO.md`：课堂演示步骤与预期输出。
- `docs/Project_Proposal_IE_498.pdf`：原 proposal 副本。
- `evidence/tests.txt` / `build.txt` / `gas-report.txt`：实际运行日志。
- `evidence/local/run.json`：部署地址、四钱包、阶段快照、状态、47 笔成功交易和 8 笔预期失败交易。
- `evidence/local/transactions.csv`：成功交易记录，含 receipt status、gasUsed、gasPrice、feeWei。
- `evidence/local/failed-transactions.csv`：预期回滚交易的哈希与 gas 费用。
- `evidence/npm-audit.json`：依赖审计结果。ws 固定覆盖至 8.21.0 修复已知依赖漏洞。

预期最终余额：Alice 865、Bob 1050、Charlie 1020、Dana 1410、Faucet 800、Treasury 400 ILT，总供应 5545 ILT。Vault、Escrow、Timelock 清空，lab allowance 为 0。

## 可选 Sepolia 部署

本次未提供测试网凭证，因此未广播 Sepolia 交易；状态见 `evidence/sepolia-status.txt`。可执行流程已保留，不需要真实资金，不使用真实资产钱包。仅需免费水龙头 Sepolia ETH 支付测试网 gas。

在本机创建一个只用于测试的加密 JSON keystore，使用安全的本地环境设置以下变量（不要将值提交到仓库或粘贴到聊天）：

- `SEPOLIA_RPC_URL`：Sepolia RPC。
- `SEPOLIA_KEYSTORE`：Alice 加密 keystore 文件路径。
- `KEYSTORE_PASSWORD`：通过不回显的终端输入或密码管理器注入；脚本不打印。
- `BOB_ADDRESS` / `CHARLIE_ADDRESS` / `DANA_ADDRESS`：另三个独立测试钱包的公开地址；部署无需他们的私钥。

```sh
npm run deploy:sepolia
```

脚本检查 chain ID 11155111、钱包不重复、非零地址和测试 ETH 余额，然后部署九合约并为四钱包及 faucet/treasury/timelock 铸币。交易记录在 `evidence/sepolia/`；途中失败则保存已完成交易到 `evidence/sepolia-partial/`。重复执行会创建新部署。不自动购买 ETH，不提供或索取真实钱包私钥。测试网时间无法通过 evm_increaseTime 加速，需实际等待 24 小时；本地 demo 的时间推进不能用于 Sepolia。

## 参考资料

- [OpenZeppelin ERC-20 / SafeERC20](https://docs.openzeppelin.com/contracts/5.x/api/token/erc20)
- [Foundry 官方仓库](https://github.com/foundry-rs/foundry)
- [ethers.js v6](https://docs.ethers.org/v6/)

项目用于课程实验，未经过独立安全审计。ApprovalSecurityLab 的漏洞为教学设计；其它合约的测试通过不代表生产环境安全保证。
