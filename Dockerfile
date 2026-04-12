# ── Build Stage ──────────────────────────────────────────────────────────────
FROM rust:1-slim-bookworm AS builder

RUN apt-get update && apt-get install -y \
    build-essential clang pkg-config libssl-dev git cmake perl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/polygone
COPY . .

RUN cargo build --release

# ── Runtime Stage ─────────────────────────────────────────────────────────────
FROM python:3.11-slim-bookworm

RUN apt-get update && apt-get install -y ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /usr/src/polygone/target/release/polygone-server /usr/local/bin/polygone-server
COPY pulse.py .
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# PORT is the HTTP health-check port (used by Render / reverse proxy)
# 4001 is the libp2p P2P port
EXPOSE 8080
EXPOSE 4001

ENTRYPOINT ["./entrypoint.sh"]
CMD ["--identity", "/data/identity.p2p", "--listen", "/ip4/0.0.0.0/tcp/4001"]
