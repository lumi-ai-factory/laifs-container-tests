#!/bin/bash

module purge
module use /appl/local/laifs/modules
module load lumi-aif-singularity-bindings

cd applications/pytorch

singularity run /appl/local/laifs/containers/lumi-multitorch-latest.sif \
    bash -c "python3 -m venv venv --system-site-packages; \
        source venv/bin/activate; \
        pip install h5py"

cp /appl/local/training/LUMI-AI-Guide/tiny-imagenet-dataset.hdf5 ./train_images.hdf5

