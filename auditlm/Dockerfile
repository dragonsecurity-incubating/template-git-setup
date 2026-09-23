FROM rust:1-bookworm@sha256:93ce27a88655056a51dbdd8f5f2d7ddc071c7b0070fb288a37b5a285fc83971e AS build
WORKDIR /src

RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates build-essential pkg-config libssl-dev \
  && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ellenhp/auditlm.git .

# Build from the crate/workspace directory (not necessarily repo root)
WORKDIR /src/auditlm
RUN cargo build --release --locked

FROM debian:bookworm-slim@sha256:3783cc01769c7b2b1b83a5c5ad96c815348e28ed7da68e2e3687004faa906251
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# If the package builds a binary named "auditlm", it will be here:
COPY --from=build /src/auditlm/target/release/auditlm /usr/local/bin/auditlm
ENTRYPOINT ["/usr/local/bin/auditlm"]
