#!/bin/bash -x

podman run \
    --rm -p 9080:9080 \
    --cap-add=CHECKPOINT_RESTORE \
    dev.local/getting-started-instanton
