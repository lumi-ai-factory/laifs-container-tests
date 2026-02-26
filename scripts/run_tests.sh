#!/bin/bash

SLURM_ACCOUNT=$1
SIF_PATH=$2

GIT_COMMIT=$(git describe --always --abbrev=7 --dirty=+)

echo "Test suite commit: ${GIT_COMMIT}"

# Get test data on LUMI
bash scripts/get_lumi_data.sh

# Install dependencies for runner and container
bash scripts/setup_env.sh $SIF_PATH > /dev/null 2>&1

# Obtain Slurm allocation and run test jobs
salloc --quiet \
    --account=$SLURM_ACCOUNT \
    --partition=standard-g \
    --exclusive \
    --nodes=4 \
    --time 03:00:00 \
    bash scripts/runner.sh $SIF_PATH
