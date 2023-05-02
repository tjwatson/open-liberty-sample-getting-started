#!/bin/bash -x

podman run \
    --rm -p 9080:9080 \
    dev.local/getting-started
