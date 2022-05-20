#/bin/bash

docker run --rm --privileged \
        --interactive --tty \
        --name swift-5.5 \
        --volume "$(pwd):/web3swift" \
        --workdir "/web3swift" \
        swift:5.5 /bin/bash