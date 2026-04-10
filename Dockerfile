# --- Build Stage ---
FROM rust:1-slim-bookworm AS builder

WORKDIR /usr/src/polygone
COPY . .

# Build the core and the server
RUN cargo build --release -p polygone-server

# --- Runtime Stage ---
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /data

COPY --from=builder /usr/src/polygone/target/release/polygone-server /usr/local/bin/polygone-server

# Expose Kademlia DHT port
EXPOSE 4001

ENTRYPOINT ["polygone-server"]
CMD ["--identity", "/data/identity.key", "--listen", "/ip4/0.0.0.0/tcp/4001"]
