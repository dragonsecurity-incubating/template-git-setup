FROM rust:1-bookworm@sha256:77fac8b98f9f46062bb680b6d25d5bcaabfc400143952ebc572e924bcbedc3fa AS build
WORKDIR /src

RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates build-essential pkg-config libssl-dev \
  && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ellenhp/auditlm.git .

# Build from the crate/workspace directory (not necessarily repo root)
WORKDIR /src/auditlm
RUN cargo build --release --locked

FROM debian:bookworm-slim@sha256:abd67ffcfa541b485a3dff59865ab629aa048a6c613e639d36e7456b0b229241
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# If the package builds a binary named "auditlm", it will be here:
COPY --from=build /src/auditlm/target/release/auditlm /usr/local/bin/auditlm
ENTRYPOINT ["/usr/local/bin/auditlm"]
