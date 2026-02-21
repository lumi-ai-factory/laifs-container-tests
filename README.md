# LUMI AI Factory Container Tests

**Performance benchmarks for LUMI AI Factory container images.**

This repository provides a set of tests for benchmarking container images built using the
[LUMI AI Factory container recipes](https://github.com/lumi-ai-factory/laifs-container-recipes).

---

## Overview

**This repository contains:**

- **Definition files** for running tests on the LUMI supercomputer using the
  [Unframe test runner](https://github.com/viahlgre/unframe) (WIP).
- **Configuration files** for specifying additional parameters for tests.
- **Application benchmarks** representative of typical usage. Each application directory contains:
    - **Benchmark files** for running deep learning workloads.
    - A **source file** listing the origins of the benchmark files.
    - A **diff file** providing a Git-style summary of any local changes to the benchmark files.

---

## Usage

### Configuring job parameters

Passing certain arguments to the Unframe runner, such as the Slurm accounting identifier and path
to the image file, is done using JSON configuration files stored in the `config` directory.  When
testing a container image, you should start by writing a configuration file for it. This repository
includes a configuration file for running the
`lumi-multitorch-full-u24r64f21m43t29-20260216_093549` image on LUMI, which can be adapted for
other images and systems.

> [!NOTE]
> When using the configuration files provided in this repository, change the `account` parameter to
> your LUMI project identifier.

### Setting up environment

Run the setup script to copy over data files and install dependencies for the test runner and
container image. By default, the script sets up a virtual environment for the image specified in the
configuration file that is last in alphabetical order in the `config` directory. Provided the
configuration files follow the naming scheme of LUMI AIF container image releases, this corresponds
to the most recent release.

Set up environment using the last configuration file in alphabetical order:
```bash
bash scripts/setup.sh
```

Set up environment using a specific configuration file:
```bash
bash scripts/setup.sh config/lumi-multitorch-full-u24r64f21m43t29-20260216_093549.json
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

Bind directories on LUMI:
```bash
module purge
module use /appl/local/laifs/modules
module load lumi-aif-singularity-bindings
```

Bind directories on other systems:
```bash
export SINGULARITY_BIND=<foo>,<bar>,  # replace with the desired directories
```

Having completed the previous steps, you are ready to run the tests. Below are a few examples of
how to use Unframe for this.

Run all tests:
```bash
unframe --dir definitions \
    --extra-args-file config/lumi-multitorch-full-u24r64f21m43t29-20260216_093549.json
```

Run test(s) with the name `transformers-inference-sdpa`:
```bash
unframe --dir definitions --name transformers-inference-sdpa \
    --extra-args-file config/lumi-multitorch-full-u24r64f21m43t29-20260216_093549.json
```

Run test(s) with the tag `transformers`:
```bash
unframe --dir definitions --tag transformers \
    --extra-args-file config/lumi-multitorch-full-u24r64f21m43t29-20260216_093549.json
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

This project is licensed under the [MIT License](LICENSE).

