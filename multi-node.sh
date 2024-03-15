#!/bin/bash
# shellcheck disable=SC2086

set -euox pipefail

bash build-bin.sh

CHEQD_CHAIN_ID="cheqd"
CHEQD_BINARY_NAME=./cheqd-noded-latest
KEYRING="--keyring-backend=test"
DENOM=ncheq

CHEQD_HOME_DIR1="test-node1"
CHEQD_HOME1="--home=$CHEQD_HOME_DIR1"
CHEQD_KEYNAME1="cheqd-user"

rm -rf $CHEQD_HOME_DIR1
# Node
$CHEQD_BINARY_NAME init $CHEQD_KEYNAME1 --chain-id "$CHEQD_CHAIN_ID" $CHEQD_HOME1
NODE_0_VAL_PUBKEY=$($CHEQD_BINARY_NAME tendermint show-validator $CHEQD_HOME1)

# User
$CHEQD_BINARY_NAME keys add $CHEQD_KEYNAME1 $KEYRING $CHEQD_HOME1

# Config
sed -i "s|minimum-gas-prices = \"\"|minimum-gas-prices = \"0${DENOM}\"|g" "$CHEQD_HOME_DIR1/config/app.toml"

sed -i 's|laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|g' "$CHEQD_HOME_DIR1/config/config.toml"
sed -i 's|address = "localhost:9090"|address = "0.0.0.0:9090"|g' "$CHEQD_HOME_DIR1/config/app.toml"
sed -i 's|log_level = "error"|log_level = "info"|g' "$CHEQD_HOME_DIR1/config/config.toml"
sed -i 's|log_format = "json"|log_format = "plain"|g' "$CHEQD_HOME_DIR1/config/config.toml"
sed -i 's|timeout_commit = "5s"|timeout_commit = "500ms"|g' "$CHEQD_HOME_DIR1/config/config.toml"

# multi-node
sed -i 's|addr_book_strict = true|addr_book_strict = false|g' "$CHEQD_HOME_DIR1/config/config.toml"

# # pruning
# sed -i 's|pruning = "default"|pruning = "custom"|g' "$CHEQD_HOME_DIR1/config/app.toml"
# sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "10"|g' "$CHEQD_HOME_DIR1/config/app.toml"
# sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' "$CHEQD_HOME_DIR1/config/app.toml"

# Genesis
sed -i "s/\"stake\"/\"$DENOM\"/" "$CHEQD_HOME_DIR1/config/genesis.json"

$CHEQD_BINARY_NAME genesis add-genesis-account $CHEQD_KEYNAME1 1000000000000000000$DENOM $KEYRING $CHEQD_HOME1
$CHEQD_BINARY_NAME genesis gentx $CHEQD_KEYNAME1 10000000000000000$DENOM --chain-id $CHEQD_CHAIN_ID --pubkey "$NODE_0_VAL_PUBKEY" $KEYRING $CHEQD_HOME1
$CHEQD_BINARY_NAME genesis collect-gentxs $CHEQD_HOME1
$CHEQD_BINARY_NAME genesis validate-genesis $CHEQD_HOME1

# $CHEQD_BINARY_NAME start $CHEQD_HOME1

# -----------------------------------------------------------------------------------
# node 2

CHEQD_HOME_DIR2="test-node2"
CHEQD_HOME2="--home=$CHEQD_HOME_DIR2"
CHEQD_KEYNAME2="cheqd-user2"

rm -rf $CHEQD_HOME_DIR2

# Node
$CHEQD_BINARY_NAME init $CHEQD_KEYNAME2 --chain-id "$CHEQD_CHAIN_ID" $CHEQD_HOME2

NODE_0_VAL_PUBKEY2=$($CHEQD_BINARY_NAME tendermint show-validator $CHEQD_HOME2)

NODE_ID=$($CHEQD_BINARY_NAME tendermint show-node-id --home $CHEQD_HOME_DIR1)
echo $NODE_ID

# User
$CHEQD_BINARY_NAME keys add $CHEQD_KEYNAME2 $KEYRING $CHEQD_HOME2

# Config
sed -i "s|minimum-gas-prices = \"\"|minimum-gas-prices = \"50${DENOM}\"|g" "$CHEQD_HOME_DIR2/config/app.toml"
sed -i 's|laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26647"|g' "$CHEQD_HOME_DIR2/config/config.toml"
sed -i 's|laddr = "tcp://0.0.0.0:26656"|laddr = "tcp://0.0.0.0:26646"|g' "$CHEQD_HOME_DIR2/config/config.toml"

sed -i 's|pprof_laddr = "localhost:6060"|pprof_laddr = "localhost:6160"|g' "$CHEQD_HOME_DIR2/config/config.toml"
sed -i 's|address = "tcp://localhost:1317"|address = "tcp://0.0.0.0:1318"|g' "$CHEQD_HOME_DIR2/config/app.toml"
sed -i 's|address = "localhost:9090"|address = "0.0.0.0:9190"|g' "$CHEQD_HOME_DIR2/config/app.toml"
sed -i 's|log_level = "error"|log_level = "info"|g' "$CHEQD_HOME_DIR2/config/config.toml"
sed -i 's|log_format = "json"|log_format = "plain"|g' "$CHEQD_HOME_DIR2/config/config.toml"
sed -i 's|timeout_commit = "5s"|timeout_commit = "500ms"|g' "$CHEQD_HOME_DIR2/config/config.toml"

# multi-node
sed -i 's|addr_book_strict = true|addr_book_strict = false|g' "$CHEQD_HOME_DIR2/config/config.toml"

# Genesis
sed -i "s/\"stake\"/\"$DENOM\"/" "$CHEQD_HOME_DIR2/config/genesis.json"

# pruning
sed -i 's|pruning = "default"|pruning = "nothing"|g' "$CHEQD_HOME_DIR2/config/app.toml"
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' "$CHEQD_HOME_DIR2/config/app.toml"
sed -i 's|pruning-interval = "0"|pruning-interval = "1000"|g' "$CHEQD_HOME_DIR2/config/app.toml"

cp $CHEQD_HOME_DIR1/config/genesis.json $CHEQD_HOME_DIR2/config/genesis.json

$CHEQD_BINARY_NAME genesis add-genesis-account $CHEQD_KEYNAME2 1000000000000000000$DENOM $KEYRING $CHEQD_HOME2
$CHEQD_BINARY_NAME genesis gentx $CHEQD_KEYNAME2 1000000000000000$DENOM --chain-id $CHEQD_CHAIN_ID --pubkey "$NODE_0_VAL_PUBKEY2" $KEYRING $CHEQD_HOME2

# share the genesis
cp $CHEQD_HOME_DIR1/config/gentx/gentx*.json $CHEQD_HOME_DIR2/config/gentx/

cp $CHEQD_HOME_DIR2/config/genesis.json $CHEQD_HOME_DIR1/config/genesis.json
$CHEQD_BINARY_NAME genesis collect-gentxs $CHEQD_HOME2
$CHEQD_BINARY_NAME genesis validate-genesis $CHEQD_HOME2

cp $CHEQD_HOME_DIR2/config/genesis.json $CHEQD_HOME_DIR1/config/genesis.json
# sed -i "s|persistent_peers = \"\"|persistent_peers = \"$NODE_ID@localhost:26656\"|g" "$CHEQD_HOME_DIR2/config/config.toml"

# this will prompt the commands you need to run them manually to check the logs
echo $CHEQD_BINARY_NAME start --home $CHEQD_HOME_DIR1
echo $CHEQD_BINARY_NAME start --home $CHEQD_HOME_DIR2
