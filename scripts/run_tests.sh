#!/bin/bash

SLURM_ACCOUNT=$1
SIF_PATH=$2
RELEASE_NAME=$3

IMAGE_NAME=$(basename $SIF_PATH .sif)
SYSTEM_NAME=$(scontrol show config | awk '/ClusterName/ {print $3}')

GIT_URL="https://github.com/lumi-ai-factory/laifs-container-tests"
GIT_COMMIT=$(git describe --always --abbrev=7 --dirty=+)

cat << EOF
# Results of automated tests for $RELEASE_NAME

Image: $IMAGE_NAME
System: $SYSTEM_NAME
Test suite URL: $GIT_URL
Test suite commit: $GIT_COMMIT

EOF

# Get test data on LUMI
bash scripts/get_lumi_data.sh

# Install dependencies for runner and container
bash scripts/setup_env.sh $SIF_PATH > /dev/null 2>&1

if [[ -z "$SLURM_PARTITION" ]]; then
    SLURM_PARTITION="standard-g"
fi

# Obtain Slurm allocation and run test jobs
salloc --quiet \
    --account=$SLURM_ACCOUNT \
    --partition=$SLURM_PARTITION \
    --exclusive \
    --nodes=4 \
    --time 03:00:00 \
    bash scripts/test_runner.sh $SIF_PATH
