FROM rust:1-bookworm@sha256:e9da6f6c3ed5095fd5d33bf7cdf309830a178a8147888f1b2f76d5769bd9306c AS build
WORKDIR /src

RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates build-essential pkg-config libssl-dev \
  && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ellenhp/auditlm.git .

# Build from the crate/workspace directory (not necessarily repo root)
WORKDIR /src/auditlm
RUN cargo build --release --locked

FROM debian:bookworm-slim@sha256:7ff6ba31527b9e336162fa061746c366c4b2032f4d2cff2078bea43f78efe3f8
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# If the package builds a binary named "auditlm", it will be here:
COPY --from=build /src/auditlm/target/release/auditlm /usr/local/bin/auditlm
ENTRYPOINT ["/usr/local/bin/auditlm"]
