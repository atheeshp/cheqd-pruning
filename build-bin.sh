#!/bin/bash

set -euox pipefail

# Define the repository URL
REPO_URL="git@github.com:cheqd/cheqd-node.git"

# Define the directory name
DIR_NAME="cheqd-node"

# Check if the directory already exists
if [ -d "$DIR_NAME" ]; then
    echo "Directory $DIR_NAME already exists. Fetching latest changes."
    # Change directory to the repository
    cd "$DIR_NAME" || exit
    # Fetch the latest changes
    git fetch
else
    # Clone the repository
    git clone "$REPO_URL" "$DIR_NAME"
    # Change directory to the repository
    cd "$DIR_NAME" || exit
fi

# Checkout to the develop branch
git checkout develop

# Build the project
make build

cd ../
cp cheqd-node/build/cheqd-noded cheqd-noded-latest
