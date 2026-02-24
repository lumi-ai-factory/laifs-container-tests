#!/bin/bash

SIF_PATH=$1

module --quiet purge
module use /appl/local/laifs/modules
module load lumi-aif-singularity-bindings

source .virtualenvs/runner/bin/activate

unframe --dir jobs --tag release --extra-args "{\"sif\": \"${SIF_PATH}\"}"
