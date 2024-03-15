#!/bin/bash

set -euox pipefail

# build the latest binary
CHAIN_BINARY_NAME=./cheqd-noded-latest
SIZE_FILE="csvs/size.csv" # result data to stored
PREVIOUS_HEIGHT=0
RETRY_COUNT=5
RETRY_INTERVAL=0.1

# disk usage will be checked at every block
check_block_height() {
    while true; do
        # retry for 0.1seconds if error occurs.
        for ((retry = 0; retry < $RETRY_COUNT; retry++)); do
            latest_block_height=$($CHAIN_BINARY_NAME status 2>&1 | jq -r '.SyncInfo.latest_block_height' && break || sleep $RETRY_INTERVAL)
        done

        if [ -z "$latest_block_height" ]; then
            echo "Failed to get latest block height after $RETRY_COUNT retries."
            continue
        fi

        echo "Latest block height: $latest_block_height"

        if [ "$latest_block_height" -gt "$PREVIOUS_HEIGHT" ]; then
            NODE1_SIZE=$(du -s test-node1 2>/dev/null | cut -f1)
            NODE2_SIZE=$(du -s test-node2 2>/dev/null | cut -f1)
            echo "$latest_block_height, $NODE1_SIZE, $NODE2_SIZE" >> "$SIZE_FILE"
            PREVIOUS_HEIGHT="$latest_block_height"
        fi

        # Sleep for 0.2 seconds
        sleep 0.2
    done
}

# Removes csvs/size.txt if it exists
rm -f "$SIZE_FILE"
echo "height, node1-size, node2-size" >> "$SIZE_FILE"

check_block_height
