#!/bin/bash

# Script to mine a CREATE2 salt for a specific address prefix

set -e

if [ "$#" -lt 1 ]; then
    echo "Usage: ./mine-address.sh <prefix>"
    echo ""
    echo "Example: ./mine-address.sh e0abc"
    echo ""
    echo "Note: The prefix should be valid hexadecimal (0-9, a-f)"
    exit 1
fi

# OpenZeppelin Create2 Deployer
DEPLOYER=0x4e59b44847b379578588920ca78fbf26c0b4956c
PREFIX=$1

echo "🔧 Getting EOAMultisend bytecode hash..."

# Get the creation bytecode and hash it
BYTECODE=$(forge inspect src/EOAMultisend.sol:EOAMultisend bytecode)
INIT_CODE_HASH=$(cast keccak "$BYTECODE")

echo "📦 Init code hash: $INIT_CODE_HASH"
echo ""

# Build and run the miner
cd rs
cargo build --release --bin mine-salt
cargo run --release --bin mine-salt -- "$DEPLOYER" "$INIT_CODE_HASH" "$PREFIX"

