# LUMI AI Factory Container Tests

**Performance benchmarks for LUMI AI Factory container images.**

This repository provides a set of tests for benchmarking container images built using the
[LUMI AI Factory container recipes](https://github.com/lumi-ai-factory/laifs-container-recipes).
The included tests are intended to ensure that the container images perform well for running
typical deep learning workloads.

---

## Overview

**This repository contains:**

- **Definition and extra arg files** for running tests on the LUMI supercomputer using the
  [Unframe test runner](https://github.com/viahlgre/unframe) (WIP).
- **Benchmarks** representative of the typical usage of deep learning libraries:
    - **Benchmark files** for running deep learning workloads.
    - **Source files** listing the origins of all benchmark files obtained from external sources.
    - **Diff files** providing a Git-style summary of any local changes to external benchmark
      files.

---

## Benchmarks

This section lists currently available benchmarks as well as the sources and licenses of the
benchmark files. The tests listed for each benchmark can be found under the `definitions`
directory.

- [`benchmarks/bitsandbytes`](benchmarks/bitsandbytes)
    - Tests:
        - `bitsandbytes_inference_int8`
    - Source: [bitsandbytes-foundation/bitsandbytes](https://github.com/bitsandbytes-foundation/bitsandbytes)
    - License: [MIT License](https://github.com/bitsandbytes-foundation/bitsandbytes/blob/main/LICENSE)
- [`benchmarks/pytorch`](benchmarks/pytorch)
    - Tests:
        - `pytorch_single_gpu`
        - `pytorch_ddp_single_node`
        - `pytorch_ddp_multi_node`
    - Source: [Lumi-supercomputer/LUMI-AI-Guide](https://github.com/Lumi-supercomputer/LUMI-AI-Guide)
    - License: [Attribution 4.0 International](https://github.com/Lumi-supercomputer/LUMI-AI-Guide/blob/main/LICENSE)
- [`benchmarks/transformers`](benchmarks/transformers)
    - Tests:
        - `transformers_inference_sdpa`
        - `transformers_inference_fa2`
    - Source: [huggingface/transformers](https://github.com/huggingface/transformers/tree/main)
    - License: [Apache License 2.0](https://github.com/huggingface/transformers/blob/main/LICENSE)

For more detailed information, see the `source.json` and `diff.txt` files included in each
benchmark directory. The `source.json` file contains permalinks to all files obtained from an
external source, while any changes made to those files can be viewed in the `diff.txt` file.

Updating diff files
```bash
python3 scripts/get_diffs.py
```

Showing diff for a particular benchmark
```bash
python3 scripts/show_color_diff.py benchmark/pytorch
```

---

## Usage

### Configuring additional test parameters

Certain test parameters, such as the Slurm accounting identifier and path to the image file, are
passed to the Unframe runner using JSON files stored in the `extra-args` directory.  When
testing a container image, you should start by writing an extra args file for it. This repository
includes an extra args file for running the
`lumi-multitorch-full-u24r64f21m43t29-20260216_093549` image on LUMI, which can be adapted for
other images and systems.

> [!NOTE]
> When using the extra args files provided in this repository, change the `account` parameter to
> your LUMI project identifier.

### Setting up environment

Run `scripts/setup_env.sh` to install dependencies for the test runner and container image. By
default, the script sets up a virtual environment for the image specified in the extra args file
that is last in alphabetical order in the `extra-args` directory. Provided the extra args files
follow the naming scheme of LUMI AIF container image releases, this corresponds to the most recent
release.

Setting up using the last extra args file in alphabetical order
```bash
bash scripts/setup_env.sh
```

Setting up using a specific extra args file
```bash
bash scripts/setup_env.sh extra-args/lumi-multitorch-full-u24r64f21m43t29-20260216_093549.json
```

### Obtaining non-public data

This section lists any non-public models and datasets required by benchmarks. Some of these files
might be available system-wide on LUMI, so if you are running the benchmarks on LUMI, you can run
`scripts/get_data_lumi.sh` to copy these files to the respective benchmark directories. Otherwise,
you will need to do this manually. Models and datasets used by more than one benchmark should be
stored under a directory named `data` at the top of the directory tree of this repository.

- `benchmarks/pytorch`
    - [Tiny ImageNet](https://www.kaggle.com/c/tiny-imagenet) dataset
        - This dataset is already available on LUMI in HDF5 format and can be copied into the
          benchmark directory by running `scripts/get_data_lumi.sh`. On other systems, you need to
          download and convert the dataset to HDF5 yourself. The
          [LUMI AI guide](https://github.com/Lumi-supercomputer/LUMI-AI-Guide) provides
          [instructions for doing this](https://github.com/Lumi-supercomputer/LUMI-AI-Guide/tree/870ca3bd4ae4c7df818f5eca4af9d251b0194ec9/3-file-formats#hdf5).
        - Please have a look at the terms of access for the ImageNet dataset
          [here](https://www.image-net.org/download.php).

### Running tests

Tests are run using the Unframe test runner. Unframe accepts one or more definition files that
can be used to specify Slurm resource allocations, commands to run, as well as functions to parse
and validate the obtained results. After following the steps in the
[previous section](#setting-up-environment), Unframe should be installed in a virtual environment
located under the `.virtualenvs` directory. Activate the virtual environment to add Unframe to your
`PATH`.

```bash
source .virtualenvs/runner/bin/activate
```

The LUMI AI Factory provides an Lmod environment module for setting some useful environment variables
on LUMI. The main purpose of the module is bind mounting important directories so that they can be
accessed inside the container. If you are working on LUMI, load this module. On other systems, you
can, for example, use the `SINGULARITY_BIND` environment variable to bind the directories you need.

Binding directories on LUMI
```bash
module purge
module use /appl/local/laifs/modules
module load lumi-aif-singularity-bindings
```

Binding directories on other systems
```bash
export SINGULARITY_BIND=<foo>,<bar>,  # replace with the desired directories
```

Having completed the previous steps, you are ready to run the tests. Below are a few examples of
how to use Unframe for this.

Running all tests
```bash
unframe --dir definitions \
    --extra-args-file extra-args/lumi-multitorch-full-u24r64f21m43t29-20260216_093549.json
```

Running test(s) with the name `transformers_inference_sdpa`
```bash
unframe --dir definitions --name transformers_inference_sdpa \
    --extra-args-file extra-args/lumi-multitorch-full-u24r64f21m43t29-20260216_093549.json
```

Running test(s) with the tag `transformers`
```bash
unframe --dir definitions --tag transformers \
    --extra-args-file extra-args/lumi-multitorch-full-u24r64f21m43t29-20260216_093549.json
```

For more information on how to use Unframe, run `unframe --help`.

### Inspecting results

The results of any tests you run are printed to your terminal. Additionally, Unframe logs the
results in CSV files, which are by default located under `out/perflogs/generic\:default/`. 

---

## Contributing

We welcome contributions! Please open an
[issue](https://github.com/lumi-ai-factory/laifs-container-tests/issues) or submit a pull request.

---

## License

This project is licensed under the [MIT License](LICENSE). For the licensing information of
external sources used in the projcet, please see the [Benchmarks section](#benchmarks).

