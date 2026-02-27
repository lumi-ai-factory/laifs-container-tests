#!/bin/bash

SLURM_ACCOUNT=$1
SIF_PATH=$2

GIT_URL="https://github.com/lumi-ai-factory/laifs-container-tests"
GIT_COMMIT=$(git describe --always --abbrev=7 --dirty=+)

echo "Test suite URL: ${GIT_URL}"
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
    bash scripts/test_runner.sh $SIF_PATH
