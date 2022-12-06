#!/bin/sh

SWIFT_VERSION=5.3

cd "$(dirname "$0")"

function downloadAndUnzip {
    curl -L -o tool.zip $2
    unzip -o -d $1/ tool.zip
    rm tool.zip
}

if ! which bin/swiftformat >/dev/null; then
    echo "warning: SwiftFormat not installed, installing..."

    mkdir -p -- "bin"
    cd bin
    rm -r ./*

    downloadAndUnzip "SwiftFormatTmp" "https://github.com/nicklockwood/SwiftFormat/releases/download/0.50.3/swiftformat.artifactbundle.zip"
    mv -f ./SwiftFormatTmp/swiftformat.artifactbundle/swiftformat-0.50.3-macos/bin/swiftformat .
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
    bin/swiftformat ../web3swift/src/ --config "swiftformat.yml" --swiftversion $SWIFT_VERSION
    cleanup
}

lint() {
    bin/swiftformat --lint ../web3swift/src/ --config "swiftformat.yml" --swiftversion $SWIFT_VERSION
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
