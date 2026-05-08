#!/bin/bash

set -e  # Exit if any command fails

SLURM_ACCOUNT=$1
SIF_PATH=$2
RELEASE_NAME=$3

# Default to 'standard-g' partition
if [[ -z "$SLURM_PARTITION" ]]; then
    SLURM_PARTITION="standard-g"
fi

#
# Print test header
#

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

#
# Get ImageNet training data for LUMI AI guide PyTorch examples
#

IMAGENET_SOURCE=/appl/local/training/LUMI-AI-Guide/tiny-imagenet-dataset.hdf5
IMAGENET_TARGET=benchmarks/pytorch/train_images.hdf5

if [ -f $IMAGENET_SOURCE ] && [ ! -f $IMAGENET_TARGET ]; then
    cp $IMAGENET_SOURCE $IMAGENET_TARGET
fi

#
# Setup virtual environments
#

mkdir -p .virtualenvs

# Unframe
if [ ! -d .virtualenvs/unframe ]; then
    python3.11 -m venv .virtualenvs/unframe
fi
.virtualenvs/unframe/bin/pip install \
    -U pip --force-reinstall -r requirements/unframe.txt > /dev/null 2>&1

# Container
singularity run -B=$PWD $SIF_PATH bash -c "if [ ! -d .virtualenvs/$IMAGE_NAME ]; then \
    python3 -m venv .virtualenvs/$IMAGE_NAME --system-site-packages; \
    fi; \
    .virtualenvs/$IMAGE_NAME/bin/pip install -r requirements/container.txt > /dev/null 2>&1"

#
# Run tests
#

module --quiet purge && module --quiet load Local-LAIF lumi-aif-singularity-bindings

salloc --quiet \
    --account=$SLURM_ACCOUNT \
    --partition=$SLURM_PARTITION \
    --exclusive \
    --nodes=4 \
    --time 03:00:00 \
    .virtualenvs/unframe/bin/unframe \
        --dir jobs --tag release --extra-args "{\"sif\": \"${SIF_PATH}\"}"
