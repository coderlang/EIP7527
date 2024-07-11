#!/bin/bash

# 检查是否提供了账户地址
if [ -z "$1" ]; then
  echo "Usage: $0 <account_address>"
  exit 1
fi

# 账户地址
ACCOUNT=$1

# 查询账户余额
balance=$(cast balance $ACCOUNT)

# 将余额从 wei 转换为 ether
balance_ether=$(cast --from-wei $balance ether)

# 输出结果
echo "Account: $ACCOUNT"
echo "Balance: $balance wei"
echo "Balance: $balance_ether ether"

