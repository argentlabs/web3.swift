#!/bin/sh

SWIFT_VERSION=5.9
SWIFTFORMAT_VERSION=0.57.2

cd "$(dirname "$0")"

function downloadAndUnzip {
    curl -L -o tool.zip $2
    unzip -o -d $1/ tool.zip
    rm tool.zip
}

# Check the cached binary's version, not just its presence. A stale cache from an older
# release fails with a misleading "Unknown option" against the current config file.
if [ -x bin/swiftformat ]; then
    INSTALLED_VERSION=$(bin/swiftformat --version 2>/dev/null)
else
    INSTALLED_VERSION=""
fi

if [ "$INSTALLED_VERSION" != "$SWIFTFORMAT_VERSION" ]; then
    if [ -n "$INSTALLED_VERSION" ]; then
        echo "warning: SwiftFormat $INSTALLED_VERSION found, need $SWIFTFORMAT_VERSION. Reinstalling..."
    else
        echo "warning: SwiftFormat not installed, installing $SWIFTFORMAT_VERSION..."
    fi

    mkdir -p -- "bin"
    cd bin
    rm -rf ./*

    downloadAndUnzip "SwiftFormatTmp" "https://github.com/nicklockwood/SwiftFormat/releases/download/$SWIFTFORMAT_VERSION/swiftformat.artifactbundle.zip"
    mv -f ./SwiftFormatTmp/swiftformat.artifactbundle/swiftformat-$SWIFTFORMAT_VERSION-macos/bin/swiftformat .
    find . -name "*Tmp" -type d -prune -exec rm -rf '{}' +
    for entry in ./*
    do
        chmod +x "$entry"
    done
    cd ../
fi

cleanup() {
    exit_code=$?
    if [[ ${exit_code} -eq 0 ]]; then
        exit 0
    else
        echo "Need to run scripts/prepareForPush.sh script to prepare the code before a PullRequest."
        exit 1
    fi
}

format() {
    bin/swiftformat ../web3swift/src/ --config "config.swiftformat" --swiftversion $SWIFT_VERSION
    cleanup
}

lint() {
    bin/swiftformat --lint ../web3swift/src/ --config "config.swiftformat" --swiftversion $SWIFT_VERSION
    cleanup
}

while getopts "fl" o; do
    case "${o}" in
        f)
            format;
            exit;;
        l)
            lint;
            exit;;
        *)
            exit;;
    esac
done

format
