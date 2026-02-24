#!/bin/bash

# Exit setup if any command fails
set -e

# Get training data for PyTorch tests. This only works on LUMI, since the ImageNet dataset is
# already available there.
tiny_imagenet_dataset=/appl/local/training/LUMI-AI-Guide/tiny-imagenet-dataset.hdf5
train_images=data/pytorch/train_images.hdf5
if [ -f $tiny_imagenet_dataset ] && [ ! -f $train_images ]; then
    mkdir -p data/pytorch
    cp $tiny_imagenet_dataset $train_images
fi
