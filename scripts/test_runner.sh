#!/bin/bash

SIF_PATH=$1

module --quiet purge
module load Local-LAIF lumi-aif-singularity-bindings

source .virtualenvs/runner/bin/activate

unframe --dir jobs --tag release --extra-args "{\"sif\": \"${SIF_PATH}\"}"
