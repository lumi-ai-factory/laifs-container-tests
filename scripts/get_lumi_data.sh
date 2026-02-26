#!/bin/bash

#
# Get ImageNet training data for LUMI AI guide PyTorch examples.
# This only works on LUMI, since the ImageNet dataset is made available there.
#

imagenet_source=/appl/local/training/LUMI-AI-Guide/tiny-imagenet-dataset.hdf5
imagenet_target=benchmarks/pytorch/train_images.hdf5

if [ -f $imagenet_source ] && [ ! -f $imagenet_target ]; then
    cp $imagenet_source $imagenet_target
fi
