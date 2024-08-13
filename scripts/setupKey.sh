#!/bin/sh

# Move one directory up from the script directory
cd "$(dirname "$0")/.."

# Write the first argument to TestConfig_private.swift
echo "extension TestConfig {\nstatic let privateKey = \"$1\"\nstatic let publicKey = \"0xE78e5ecb061fE3DD1672dDDA7b5116213B23B99A\"\n}" > Tests/Web3SwiftTests/TestConfigPrivate.swift
