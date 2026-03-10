# LUMI AI Factory Container Tests

**Performance benchmarks for LUMI AI Factory container images.**

This repository provides a set of tests for benchmarking container images built using the
[LUMI AI Factory container recipes](https://github.com/lumi-ai-factory/laifs-container-recipes).
The included tests are intended to ensure that the container images perform well for running
typical deep learning workloads.

---

## Overview

**This repository contains:**

- **Job files** for running test jobs on the LUMI supercomputer using the
  [Unframe test runner](https://github.com/viahlgre/unframe) (WIP).
- **Benchmarks** representative of the typical usage of deep learning libraries:
    - **Benchmark files** for running deep learning workloads.
    - **Source files** listing the origins of all benchmark files obtained from external sources.
    - **Diff files** providing a Git-style summary of any local changes to external benchmark
      files.
- **Scripts** for running sets of tests as well as tracking and inspecting local changes to
  external benchmark files.

---

## Benchmarks

This section lists currently available benchmarks as well as the sources and licenses of any
benchmark files. The test jobs listed for each benchmark can be found under the `jobs`
directory.

- Accelerate
    - Tests:
        - `accelerate-big-model-inference`
    - Sources:
        - [huggingface/accelerate](https://github.com/huggingface/accelerate)
            - License: [Apache License 2.0](https://github.com/huggingface/accelerate/blob/main/LICENSE)
- BitsAndBytes
    - Tests:
        - `bitsandbytes-inference`
        - `bitsandbytes-inference-int8`
    - Sources:
        - [bitsandbytes-foundation/bitsandbytes](https://github.com/bitsandbytes-foundation/bitsandbytes)
            - License: [MIT License](https://github.com/bitsandbytes-foundation/bitsandbytes/blob/main/LICENSE)
- MPI
    - Tests:
        - `osu-intra-node-gcd2gcd-bw`
        - `osu-inter-node-gcd2gcd-bw`
- PEFT
    - Tests:
        - `peft-alora-finetuning`
    - Sources:
        - [huggingface/peft](https://github.com/huggingface/peft)
            - License: [Apache License 2.0](https://github.com/lumi-ai-factory/laifs-container-tests/tree/mai://github.com/huggingface/peft/blob/main/LICENSE)
- PyTorch
    - Tests:
        - `pytorch-single-gpu`
        - `pytorch-ddp-single-node`
        - `pytorch-ddp-multi-node`
        - `pytorch-ds-single-node`
        - `pytorch-ds-multi-node`
    - Sources:
        - [Lumi-supercomputer/LUMI-AI-Guide](https://github.com/Lumi-supercomputer/LUMI-AI-Guide)
            - License: [Attribution 4.0 International](https://github.com/Lumi-supercomputer/LUMI-AI-Guide/blob/main/LICENSE)
- Transformers
    - Tests:
        - `transformers-inference`
    - Sources:
        - [huggingface/transformers](https://github.com/huggingface/transformers/tree/main)
            - License: [Apache License 2.0](https://github.com/huggingface/transformers/blob/main/LICENSE)
- vLLM
    - Tests:
        - `vllm-bench-single-gpu-llama31-8b`
        - `vllm-bench-full-node-gpt-oss-120b`

For more detailed information, see the `ext.json` and `ext.diff` files included in each
benchmark directory. The `ext.json` file contains permalinks to all files obtained from an
external source, while any changes made to those files can be viewed in the `ext.diff` file.
If you want to view the diff files with syntax highlighting, you can use, for example, the
[Pygments CLI](https://pygments.org/docs/cmdline/).

Updating diff files
```bash
python3 scripts/get_diffs.py
```

---

## Usage

### Obtaining data for benchmarks

This section lists any non-public models and datasets required by benchmarks. Some of these files
might be available system-wide on LUMI. If you are working on LUMI, these files are copied to the
respective benchmark directories when running `scripts/run_tests.sh`. Otherwise, you will need to
do this manually. Models and datasets used by more than one benchmark should be stored under a
directory named `data` at the top of the directory tree of this repository.

- `benchmarks/pytorch`
    - [Tiny ImageNet](https://www.kaggle.com/c/tiny-imagenet) dataset
        - This dataset is already available on LUMI in HDF5 format and can be copied into the
          benchmark directory by running `scripts/get_lumi_data.sh`. On other systems, you need to
          download and convert the dataset to HDF5 yourself. The
          [LUMI AI guide](https://github.com/Lumi-supercomputer/LUMI-AI-Guide) provides
          [instructions for doing this](https://github.com/Lumi-supercomputer/LUMI-AI-Guide/tree/870ca3bd4ae4c7df818f5eca4af9d251b0194ec9/3-file-formats#hdf5).
        - Please have a look at the terms of access for the ImageNet dataset
          [here](https://www.image-net.org/download.php).

### Running tests

Tests are run using the Unframe test runner. Unframe accepts one or more job files that
can be used to specify Slurm parameters, commands to run, as well as functions to parse
and validate the obtained results. The `scripts/run_tests.sh` script
installs dependencies for both the test runner and container image being tested, obtains a Slurm
allocation, and runs all test jobs. For instance, to test the
`lumi-multitorch-full-u24r64f21m43t29-20260216_093549` container image, one can run the following
command (with the placeholder project ID replaced with that of a real LUMI project).

```bash
bash scripts/run_tests.sh \
    <your-project-id> \
    /appl/local/laifs/containers/lumi-multitorch-u24r64f21m43t29-20260216_093549/lumi-multitorch-full-u24r64f21m43t29-20260216_093549.sif
```

### Inspecting results

The results of any tests you run are printed to your terminal. Additionally, Unframe logs the
results in CSV files, which are by default located under `out/perflogs/generic:default/`. 

---

## Contributing

We welcome contributions! Please open an
[issue](https://github.com/lumi-ai-factory/laifs-container-tests/issues) or submit a pull request.

---

## License

This project is licensed under the [MIT License](LICENSE). For the licensing information of
external sources used in the projcet, please see the [Benchmarks section](#benchmarks).

