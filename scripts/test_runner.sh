#!/bin/bash

SIF_PATH=$1

module --quiet purge && module --quiet load Local-LAIF lumi-aif-singularity-bindings

.virtualenvs/unframe/bin/unframe \
    --dir jobs --tag release --extra-args "{\"sif\": \"${SIF_PATH}\"}"
