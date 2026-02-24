#!/bin/bash

# Exit setup if any command fails
set -e

# If no extra args file is provided, choose last in alphabetical order
extra_args_file=$1
if [ -z $extra_args_file ]; then
    extra_args_file=$(ls -1 ./extra-args/* | tail -n 1)
fi
sif=$(cat $extra_args_file | jq -r .sif)
image_name=$(basename $sif .sif)

echo "Running setup for image $image_name"
echo

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
singularity run -B $PWD $sif bash -c "if [ ! -d .virtualenvs/$image_name ]; then \
    python3 -m venv .virtualenvs/$image_name --system-site-packages; \
    fi; \
    source .virtualenvs/$image_name/bin/activate; \
    pip install -r requirements/container.txt"
echo

echo "Setup complete!"
