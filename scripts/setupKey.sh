#!/bin/sh

# write first argument to a Test
echo "extension TestConfig {\nstatic let privateKey = \"$1\"\nstatic let publicKey = \"0xE78e5ecb061fE3DD1672dDDA7b5116213B23B99A\"\n}" > web3sTests/TestConfig_private.swift