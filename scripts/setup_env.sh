#!/bin/bash

SIF_PATH=$1
IMAGE_NAME=$(basename $SIF_PATH .sif)

# Exit setup if any command fails
set -e

# Create directory for virtual environments
mkdir -p .virtualenvs

# Set up runner environment
if [ ! -d .virtualenvs/runner ]; then
    python3 -m venv .virtualenvs/runner
fi
source .virtualenvs/runner/bin/activate
pip install -U pip -r requirements/runner.txt
deactivate
echo

# Set up container environment
singularity run -B $PWD $SIF_PATH bash -c "if [ ! -d .virtualenvs/$IMAGE_NAME ]; then \
    python3 -m venv .virtualenvs/$IMAGE_NAME --system-site-packages; \
    fi; \
    source .virtualenvs/$IMAGE_NAME/bin/activate; \
    pip install -r requirements/container.txt"
echo
