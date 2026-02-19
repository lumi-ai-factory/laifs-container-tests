#!/bin/bash

module purge
module use /appl/local/laifs/modules
module load lumi-aif-singularity-bindings

# Download training data for PyTorch tests
mkdir --parents data
cp /appl/local/training/LUMI-AI-Guide/tiny-imagenet-dataset.hdf5 data/train_images.hdf5

# Set up runner environment
python3 -m venv runner-env
source runner-env/bin/activate
pip install -U pip -r requirements_runner.txt
deactivate

# Set up execution environment
singularity run /appl/local/laifs/containers/lumi-multitorch-latest.sif \
    bash -c "python3 -m venv exec-env --system-site-packages; \
        source exec-env/bin/activate; \
        pip install -r requirements_exec.txt"
