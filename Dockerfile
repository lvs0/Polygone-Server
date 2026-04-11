# --- Build Stage ---
FROM rust:1-slim-bookworm AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/polygone
# Copy only the server files
COPY . .

# Build the server (core will be pulled from git as defined in Cargo.toml)
RUN cargo build --release

# --- Runtime Stage ---
FROM python:3.11-slim-bookworm

# Install CA certificates
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy binary
COPY --from=builder /usr/src/polygone/target/release/polygone-server /usr/local/bin/polygone-server

# Copy pulse and entrypoint (which are now at root of repo)
COPY pulse.py .
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Render expects the app to bind to $PORT
EXPOSE 8080
EXPOSE 4001

ENTRYPOINT ["./entrypoint.sh"]
CMD ["--identity", "/app/identity.p2p", "--listen", "/ip4/0.0.0.0/tcp/4001"]
