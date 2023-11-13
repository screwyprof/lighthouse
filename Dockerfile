FROM rust:1.69.0-bullseye AS builder
RUN apt-get update && apt-get -y upgrade && apt-get install -y cmake libclang-dev
COPY . lighthouse
ARG FEATURES
ARG PROFILE=release
ENV FEATURES $FEATURES
ENV PROFILE $PROFILE
# Set the CARGO_NET_GIT_FETCH_WITH_CLI environment variable and enable sparse-registry
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true
ENV CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse
RUN cd lighthouse && make

FROM ubuntu:22.04
RUN apt-get update && apt-get -y upgrade && apt-get install -y --no-install-recommends \
  libssl-dev \
  ca-certificates \
  gdb \
  heaptrack \
  curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Download and install Bytehound
RUN curl -L https://github.com/koute/bytehound/releases/download/0.11.0/bytehound-x86_64-unknown-linux-gnu.tgz | tar xz -C /usr/local/bin
COPY --from=builder /usr/local/cargo/bin/lighthouse /usr/local/bin/lighthouse