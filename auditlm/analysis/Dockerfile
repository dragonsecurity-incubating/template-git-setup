FROM debian:bookworm-slim@sha256:74d56e3931e0d5a1dd51f8c8a2466d21de84a271cd3b5a733b803aa91abf4421
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /work
