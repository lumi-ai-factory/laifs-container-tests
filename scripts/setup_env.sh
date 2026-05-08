#!/bin/bash

SIF_PATH=$1
IMAGE_NAME=$(basename $SIF_PATH .sif)

# Exit setup if any command fails
set -e

# Create directory for virtual environments
mkdir -p .virtualenvs

# Set up runner environment
if [ ! -d .virtualenvs/runner ]; then
    python3.11 -m venv .virtualenvs/runner
fi
.virtualenvs/runner/bin/pip install \
    -U pip --force-reinstall -r requirements/runner.txt
echo

# Set up container environment
singularity run -B $PWD $SIF_PATH bash -c "if [ ! -d .virtualenvs/$IMAGE_NAME ]; then \
    python3 -m venv .virtualenvs/$IMAGE_NAME --system-site-packages; \
    fi; \
    .virtualenvs/$IMAGE_NAME/bin/pip install -r requirements/container.txt"
echo
