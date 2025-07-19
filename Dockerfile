FROM ubuntu:latest

ARG XLEN
ARG RISCV_ARCH
ARG RISCV_ABI

ENV HOME="/root"
ENV WORK="$HOME/src"
ENV RISCV="/opt/riscv"
ENV PATH="$RISCV/$RISCV_ARCH/bin:$PATH"

# locale settings
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG="en_US.utf8"

# package install
RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    autotools-dev \
    bc \
    bison \
    build-essential \
    ccache \
    cmake \
    curl \
    device-tree-compiler \
    flex \
    g++ \
    gawk \
    git \
    gperf \
    help2man \
    libboost-regex-dev \
    libboost-system-dev \
    libexpat-dev \
    libfl-dev \
    libfl2 \
    libglib2.0-dev \
    libgmp-dev \
    libgoogle-perftools-dev \
    libmpc-dev \
    libmpfr-dev \
    libslirp-dev \
    libtool \
    make \
    ninja-build \
    numactl \
    patchutils \
    perl \
    perl-doc \
    python3 \
    python3-pip \
    python3-tomli \
    texinfo \
    vim \
    zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

# Verilator
WORKDIR $WORK
RUN git clone https://github.com/verilator/verilator
WORKDIR $WORK/verilator
RUN autoconf
RUN ./configure
RUN make -j $(nproc)
RUN make install
RUN make distclean

# riscv-gnu-toolchain
WORKDIR $WORK
RUN git clone https://github.com/riscv/riscv-gnu-toolchain
WORKDIR $WORK/riscv-gnu-toolchain
RUN ./configure --prefix=$RISCV/$RISCV_ARCH --with-arch=$RISCV_ARCH --with-abi=$RISCV_ABI
RUN make -j $(nproc)
RUN make distclean

# riscv-isa-sim (spike)
WORKDIR $WORK
RUN git clone https://github.com/riscv-software-src/riscv-isa-sim.git
WORKDIR $WORK/riscv-isa-sim/build
RUN ../configure --prefix=$RISCV/$RISCV_ARCH --with-target=riscv$XLEN-unknown-elf
RUN make -j $(nproc)
RUN make install
RUN make distclean

WORKDIR $HOME
