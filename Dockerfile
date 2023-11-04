FROM rust:1.68.2-bullseye AS builder
RUN apt-get update && apt-get -y upgrade && apt-get install -y cmake libclang-dev
# Set up the nightly toolchain
RUN rustup toolchain install nightly
RUN rustup default nightly
RUN cargo install -Z sparse-registry --debug cargo-ament-build
COPY . lighthouse
ARG FEATURES
ARG PROFILE=release
ENV FEATURES $FEATURES
ENV PROFILE $PROFILE
# Set the CARGO_NET_GIT_FETCH_WITH_CLI environment variable and enable sparse-registry
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true
ENV CARGO_UNSTABLE_SPARSE_REGISTRY=true
#ENV RUSTFLAGS="-Z sparse-registry"
RUN cd lighthouse && make

FROM ubuntu:22.04
RUN apt-get update && apt-get -y upgrade && apt-get install -y --no-install-recommends \
  libssl-dev \
  ca-certificates \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local/cargo/bin/lighthouse /usr/local/bin/lighthouse