#!/bin/bash

# 设置合约地址
export APP_ADDRESS=0x67d269191c92Caf3cD7723F116c85e6E9bf55933

# 调用 getMaxSupply 函数
MAX_SUPPLY=$(cast call $APP_ADDRESS "getMaxSupply()(uint256)")
echo "Max Supply: $MAX_SUPPLY"

# 调用 getName 函数
TOKEN_ID=1
TOKEN_NAME=$(cast call $APP_ADDRESS "getName(uint256)(string)" $TOKEN_ID)
echo "Token Name: $TOKEN_NAME"

# 调用 getAgency 函数
AGENCY_ADDRESS=$(cast call $APP_ADDRESS "getAgency()(address)")
echo "Agency Address: $AGENCY_ADDRESS"

