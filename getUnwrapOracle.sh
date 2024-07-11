#!/bin/bash

# 检查是否提供了合约地址
if [ -z "$1" ]; then
  echo "Usage: $0 <contract_address>"
  exit 1
fi

# 检查是否提供了整数参数
if [ -z "$2" ]; then
  echo "Usage: $0 <contract_address> <integer>"
  exit 1
fi

# 合约地址和整数参数
AGENCY=$1
INTEGER=$2

# 将整数转换为64字节的十六进制格式
DATA=$(printf "%064x" $INTEGER)

# 调用 cast call 获取返回值
return_value=$(cast call $AGENCY "getUnwrapOracle(bytes)" "0x$DATA")

# 去掉前缀 "0x"
return_value=${return_value:2}

# 分割返回值为 price 和 fee
price_hex=${return_value:0:64}
fee_hex=${return_value:64:64}

# 将十六进制字符串转换为大写
price_hex=$(echo $price_hex | tr 'a-f' 'A-F')
fee_hex=$(echo $fee_hex | tr 'a-f' 'A-F')

# 将十六进制转换为十进制
price_dec=$(echo "ibase=16; $price_hex" | bc)
fee_dec=$(echo "ibase=16; $fee_hex" | bc)

# 输出结果
echo "Price: $price_dec"
echo "Fee: $fee_dec"

