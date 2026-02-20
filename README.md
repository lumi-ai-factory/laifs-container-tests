# LUMI AI Factory Container Tests

**Performance benchmarks for LUMI AI Factory container images.**

This repository provides a set of tests for benchmarking container images built using the
[LUMI AI Factory container recipes](https://github.com/lumi-ai-factory/laifs-container-recipes).

---

## Overview

**This repository contains:**

- **Definition files** for running tests with the [Unframe runner](github.com/viahlgre/unframe).
- **Application benchmarks** representative of the typical usage of the library in question.

---

## Usage

### Configuring job parameters

Passing certain arguments to the Unframe runner, such as the desired Slurm partition and path to
the image file, is done using JSON configuration files, which are stored in the `config` directory.
When testing a container image, you should start by writing a configuration file for it. This
repository includes a configuration file for running the
`lumi-multitorch-full-u24r64f21m43t29-20260216_093549` image on LUMI, which can be adapted for
other images and systems.

### Setting up environment

Run the setup script to copy over data files and install dependencies for the test runner and
container image. By default, the script sets up a virtual environment for the image specified in the
configuration file that is last in alphabetical order in the `config` directory. Provided the
configuration files follow the naming scheme of LUMI AIF container image releases, this corresponds
to the most recent release.

```bash
# Set up environment using the last config file in alphabetical order
bash setup.sh

# Set up environment using a specific configuration file
bash setup.sh config/lumi-multitorch-full-u24r64f21m43t29-20260216_093549.json
```

### Running tests

Tests are run using the Unframe test runner. Unframe accepts one or more definition files that
can be used to specify Slurm resource allocations, commands to run, as well as functions to parse
and validate the obtained results. After following the steps in the previous section, Unframe
should be installed in a virtual environment located under the `.virtualenvs` directory. Activate
the virtual environment to add Unframe to your `PATH`.

```bash
source .virtualenvs/runner/bin/activate
```

The LUMI AI Factory provides an Lmod environment module for setting some useful environment variables
on LUMI. The main purpose of the module is bind mounting important directories so that they can be
accessed inside the container. If you are working on LUMI, load this module. On other systems, you
can, for example, use the `SINGULARITY_BIND` environment variable to bind the directories you need.

```bash
# On LUMI
module purge
module use /appl/local/laifs/modules
module load lumi-aif-singularity-bindings

# On other systems
export SINGULARITY_BIND=<dir1>,<dir2>,  # replace with the desired directories
```

Having completed the previous steps, you are ready to run the tests. Below are a few examples of
how to use Unframe for this.

```bash
# Run all tests
unframe --dir definitions \
    --extra-args-file config/lumi-multitorch-full-u24r64f21m43t29-20260216_093549.json

# Run test with the name `transformers-inference-sdpa`
unframe --dir definitions --name transformers-inference-sdpa \
    --extra-args-file config/lumi-multitorch-full-u24r64f21m43t29-20260216_093549.json

# Run all tests with the tag `transformers`
unframe --dir definitions --tag transformers \
    --extra-args-file config/lumi-multitorch-full-u24r64f21m43t29-20260216_093549.json
```

### Inspecting results

The results of any tests you run are printed to your terminal. Additionally, Unframe logs the
results in CSV files, which are by default located under `out/perflogs/generic\:default/`. 

---

## Contributing

We welcome contributions! Please open an
[issue](https://github.com/lumi-ai-factory/laifs-container-tests/issues) or submit a pull request.

---

## License

This project is licensed under the [MIT License](LICENSE).

