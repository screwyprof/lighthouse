FROM lukemathwalker/cargo-chef:latest-rust-1.68.2-bullseye AS chef
WORKDIR app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
RUN apt-get update && apt-get -y upgrade && apt-get install -y cmake libclang-dev
# Set up the nightly toolchain
#RUN rustup toolchain install nightly
#RUN rustup default nightly
#RUN cargo install -Z sparse-registry --debug cargo-ament-build
# Build dependencies
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
# build project
COPY . lighthouse
ARG FEATURES
ARG PROFILE=release
ENV FEATURES $FEATURES
ENV PROFILE $PROFILE
# Set the CARGO_NET_GIT_FETCH_WITH_CLI environment variable and enable sparse-registry
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true
#ENV CARGO_UNSTABLE_SPARSE_REGISTRY=true
#ENV RUSTFLAGS="-Z sparse-registry"
RUN cd lighthouse && make

FROM ubuntu:22.04
RUN apt-get update && apt-get -y upgrade && apt-get install -y --no-install-recommends \
  libssl-dev \
  ca-certificates \
  gdb \
  heapstack \
  curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Download and install Bytehound
RUN curl -L https://github.com/koute/bytehound/releases/download/0.11.0/bytehound-x86_64-unknown-linux-gnu.tgz | tar xz -C /usr/local/bin
COPY --from=builder /usr/local/cargo/bin/lighthouse /usr/local/bin/lighthouse