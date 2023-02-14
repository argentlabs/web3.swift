#!/bin/sh

# write first argument to a Test
echo "extension TestConfig {\nstatic let privateKey = \"$1\"\n}" > web3sTests/TestConfig_private.swift