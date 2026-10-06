FROM rust:1-bookworm@sha256:59037199c44290f2befcdd58dcc540164763fc296950255aaefeef096a1866b0 AS build
WORKDIR /src

RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates build-essential pkg-config libssl-dev \
  && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ellenhp/auditlm.git .

# Build from the crate/workspace directory (not necessarily repo root)
WORKDIR /src/auditlm
RUN cargo build --release --locked

FROM debian:bookworm-slim@sha256:7c7b2c966bc9ee8cedfeef67e0e279108992c77681fa595db4a9d65c06ccc587
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# If the package builds a binary named "auditlm", it will be here:
COPY --from=build /src/auditlm/target/release/auditlm /usr/local/bin/auditlm
ENTRYPOINT ["/usr/local/bin/auditlm"]
