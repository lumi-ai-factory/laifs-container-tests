#!/bin/bash

set -e  # Exit if any command fails

SLURM_ACCOUNT=$1
SIF_PATH=$2
RELEASE_NAME=$3
UNFRAME_TAG=${4:-release}

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

Image: $IMAGE_NAME<br>
System: $SYSTEM_NAME<br>
Test suite URL: $GIT_URL<br>
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
    -U pip --force-reinstall -r requirements/unframe.txt 1>&2

# Container
singularity run -B=$PWD $SIF_PATH bash -c "if [ ! -d .virtualenvs/$IMAGE_NAME ]; then \
    python3 -m venv .virtualenvs/$IMAGE_NAME --system-site-packages; \
    fi; \
    .virtualenvs/$IMAGE_NAME/bin/pip install -r requirements/container.txt 1>&2"

#
# Run tests
#

module purge && module load Local-LAIF lumi-aif-singularity-bindings

if [[ $SLURM_PARTITION == dev-g ]]; then
    JOB_TIMELIMIT=02:00:00
else
    JOB_TIMELIMIT=03:00:00
fi

export OUTPUT_DIR="out/$RELEASE_NAME"
mkdir -p $OUTPUT_DIR

# Keep the MIOpen kernel cache in node-local /tmp. Its SQLite database times
# out on Lustre when many ranks write to it at the same time.
export MIOPEN_CUSTOM_CACHE_DIR=/tmp/$USER-miopen-cache/$RELEASE_NAME

# Redirect all vLLM cache files from $HOME.
export VLLM_CACHE_ROOT=$PWD/data/cache/vllm/$RELEASE_NAME
mkdir -p ${VLLM_CACHE_ROOT}

# Additional environment variables for GPU tests can be set here. For example, to limit the number of hardware queues used by the GPU
# export GPU_MAX_HW_QUEUES=2

salloc --account=$SLURM_ACCOUNT \
    --partition=$SLURM_PARTITION \
    --exclusive \
    --nodes=4 \
    --time $JOB_TIMELIMIT \
    bash -c 'echo "Nodes: $SLURM_JOB_NODELIST"; echo; exec "$@"' _ \
    .virtualenvs/unframe/bin/unframe \
        --dir unframe --tag $UNFRAME_TAG --prefix $OUTPUT_DIR --sysenv $SYSTEM_NAME --extra-args "{\"sif\": \"${SIF_PATH}\"}"
