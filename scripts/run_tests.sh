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
GIT_COMMIT=$(git describe --always --abbrev=7 --dirty=+ --exclude='*')

# Keep all output of this run in a directory named by its start time: the
# report, and unframe's stdio and perflogs
OUTPUT_DIR=out/$RELEASE_NAME/$(date -u +%Y-%m-%dT%H%M%SZ)
REPORT_DIR=$OUTPUT_DIR/reports
REPORT_FILE=$OUTPUT_DIR/$RELEASE_NAME-tests.md
mkdir -p $REPORT_DIR

cat << EOF | tee $REPORT_FILE
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

# Don't fill the pip cache in $HOME.
export PIP_NO_CACHE_DIR=1

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
    JOB_TIMELIMIT=01:00:00
else
    JOB_TIMELIMIT=02:00:00
fi

# Keep the MIOpen kernel cache in node-local /tmp. Its SQLite database times
# out on Lustre when many ranks write to it at the same time.
export MIOPEN_CUSTOM_CACHE_DIR=/tmp/$USER-miopen-cache/$RELEASE_NAME
export MIOPEN_USER_DB_PATH="${MIOPEN_CUSTOM_CACHE_DIR}"

# Keep the compiled kernels and graphs of each release between runs, so that
# later runs don't compile them again. Without these settings, vLLM, Triton,
# ROCm's run-time compiler (comgr) and tvm-ffi's PyTorch extension write to
# $HOME and Inductor to /tmp.
CACHE_DIR=$PWD/data/cache/$RELEASE_NAME
export VLLM_CACHE_ROOT=$CACHE_DIR/vllm
export TRITON_CACHE_DIR=$CACHE_DIR/triton
export TORCHINDUCTOR_CACHE_DIR=$CACHE_DIR/torchinductor
export AMD_COMGR_CACHE_DIR=$CACHE_DIR/comgr
export TVM_FFI_CACHE_DIR=$CACHE_DIR/tvm-ffi
mkdir -p $VLLM_CACHE_ROOT $TRITON_CACHE_DIR $TORCHINDUCTOR_CACHE_DIR $AMD_COMGR_CACHE_DIR $TVM_FFI_CACHE_DIR

# Don't mount $HOME in the containers, so that packages in ~/.local or files
# elsewhere in $HOME don't affect the tests
export SINGULARITY_NO_HOME=1

# Keep torchvision's pretrained weights with the other test data
export TORCH_HOME=$PWD/data/torch

# Additional environment variables for GPU tests can be set here. For example, to limit the number of hardware queues used by the GPU
# export GPU_MAX_HW_QUEUES=2

# Single-node tests are split into groups that run in parallel, each in its
# own 1-node allocation. Tests that need more nodes, or don't set --nodes, run
# in one 4-node allocation at the same time.
NUM_SINGLE_NODE_GROUPS=${NUM_SINGLE_NODE_GROUPS:-3}

# "<name> <nodes>" for each test with the tag, in the order unframe runs them
TESTS=$(.virtualenvs/unframe/bin/python3 scripts/list_tests.py unframe "$UNFRAME_TAG")

SINGLE_NODE_GROUPS=()
MULTI_NODE_TESTS=()
i=0
while read -r name nodes; do
    [[ -z $name ]] && continue
    if [[ $nodes == 1 ]]; then
        SINGLE_NODE_GROUPS[$(( i++ % NUM_SINGLE_NODE_GROUPS ))]+=" $name"
    else
        MULTI_NODE_TESTS+=("$name")
    fi
done <<< "$TESTS"

# Run the given tests in an allocation of <nodes> nodes, and write their report
# to <report file>. The report starts with the allocated nodes.
run_group() {
    local nodes=$1 report=$2
    shift 2
    local name_args=()
    for name in "$@"; do
        name_args+=(--name "$name")
    done

    salloc \
        --job-name=$JOB_NAME \
        --account=$SLURM_ACCOUNT \
        --partition=$SLURM_PARTITION \
        --exclusive \
        --nodes=$nodes \
        --time $JOB_TIMELIMIT \
        bash -c 'echo "Nodes: $SLURM_JOB_NODELIST"; exec "$@"' _ \
        .virtualenvs/unframe/bin/unframe \
        --dir unframe --tag $UNFRAME_TAG --prefix $OUTPUT_DIR --sysenv $SYSTEM_NAME --extra-args "{\"sif\": \"${SIF_PATH}\"}" \
        "${name_args[@]}" > $report
}

# Name the allocations of this run, so that they can be cancelled if the
# script is interrupted
JOB_NAME=laifs-container-tests-$$
# trap 'scancel --user=$USER --name=$JOB_NAME; exit 130' INT TERM HUP

PIDS=()
if [[ ${#MULTI_NODE_TESTS[@]} -gt 0 ]]; then
    run_group 4 $REPORT_DIR/$RELEASE_NAME-multi-node.md "${MULTI_NODE_TESTS[@]}" &
    PIDS+=($!)
fi
for g in "${!SINGLE_NODE_GROUPS[@]}"; do
    run_group 1 $REPORT_DIR/$RELEASE_NAME-single-node-$g.md ${SINGLE_NODE_GROUPS[$g]} &
    PIDS+=($!)
done

FAILED=0
for pid in "${PIDS[@]}"; do
    wait $pid || FAILED=1
done

# Merge the reports in the order unframe would run the tests, and show the
# nodes of each test under its heading. Add them to the run's report after
# the header.
.virtualenvs/unframe/bin/python3 scripts/merge_reports.py $REPORT_DIR $(cut -d' ' -f1 <<< "$TESTS") \
    | tee -a $REPORT_FILE

exit $FAILED
