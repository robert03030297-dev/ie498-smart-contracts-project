#!/bin/zsh
cd "$(dirname "$0")" || exit 1
printf '\nIE 498 智能合约自动演示\n依次执行：测试 → 九个合约部署 → 四钱包交易 → 安全实验 → 余额核对\n\n'
if ! command -v node >/dev/null || ! command -v npm >/dev/null; then
  printf '请先安装 Node.js 20+ 和 npm。\n'
  read 'answer?按回车关闭窗口…'
  exit 1
fi
if [[ ! -d node_modules ]]; then
  npm ci || exit 1
fi
if [[ ! -x .tools/solc && -z "$FOUNDRY_SOLC" ]]; then
  npm run setup || exit 1
fi
npm test && npm run demo -- --watch
result=$?
printf '\n演示结束（退出码 %s）。交易记录在 evidence/local/。\n' "$result"
read 'answer?按回车关闭窗口…'
exit "$result"
