#/bin/bash

# Matches the image used by the test_linux CI job, so a local run reproduces it.
docker run --rm --privileged \
        --interactive --tty \
        --name swift-6.1 \
        --volume "$(pwd):/web3swift" \
        --workdir "/web3swift" \
        swift:6.1-jammy /bin/bash