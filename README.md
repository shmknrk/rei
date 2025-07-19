<!-- markdownlint-disable MD014 -->

# REI

- 64-bit RISC-V Processor
- RISC-V ISA modules:
  - [x] RV64I base ISA, v2.1
  - [ ] Zifencei extension, v2.1
  - [x] Zicsr extension, v2.0
  - [ ] Zicntr extension, v2.0
  - [ ] M extension, v2.0
  - [ ] A extension, v2.1
  - [x] Machine ISA, v1.13
  - [ ] Supervisor ISA, v1.13
  - [ ] Hypervisor ISA, v1.0
- [ ] Sv39: Page-Based 39-bit Virtual-Memory System

## Build Steps

1. Install Docker and run the docker daemon.
2. Build Docker image.

```bash
$ make docker-build
```

## Running riscv-tests

```bash
$ make mount
$ git submodule update --init --recursive # only first time
$ make isa                    # run all tests
$ make isa DIFF_COMMIT_LOG=1  # run all tests and compare the commit log with the spike
$ make add                    # run add instruction test
$ make add DIFF_COMMIT_LOG=1  # run add instruction test and compare the commit log with the spike
```
