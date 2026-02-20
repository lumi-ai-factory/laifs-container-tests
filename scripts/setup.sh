#!/bin/bash

# Exit setup if any command fails
set -e

# If no config file is provided, choose last in alphabetical order
config_file=$1
if [ -z $config_file ]; then
    config_file=$(ls -1 ./config/* | tail -n 1)
fi
sif=$(cat $config_file | jq -r .sif)
image_name=$(echo $sif | sed -E 's,.*/(.*).*\..*,\1,')

echo "Running setup for image $image_name..."
echo

# Ensure required directories exist
mkdir -p .virtualenvs data

# Get training data for PyTorch tests
if [ ! -f data/pytorch/train_images.hdf5 ]; then
    cp /appl/local/training/LUMI-AI-Guide/tiny-imagenet-dataset.hdf5 data/train_images.hdf5
fi

# Set up runner environment
if [ ! -d .virtualenvs/runner ]; then
    python3 -m venv .virtualenvs/runner
fi
source .virtualenvs/runner/bin/activate
pip install -U pip -r requirements/runner.txt
deactivate
echo

# Set up container environment
ml -q purge && ml use /appl/local/laifs/modules && ml lumi-aif-singularity-bindings
singularity run $sif bash -c "if [ ! -d .virtualenvs/$image_name ]; then \
    python3 -m venv .virtualenvs/$image_name --system-site-packages; \
    fi; \
    source .virtualenvs/$image_name/bin/activate; \
    pip install -r requirements/container.txt"
echo

echo "Setup complete!"
