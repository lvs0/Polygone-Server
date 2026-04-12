#!/bin/bash
# ⬡ POLYGONE VPS RUNNER — by Hope

set -e

DATA_DIR="/data"
mkdir -p "$DATA_DIR"

# Generate identity if not exists
if [ ! -f "$DATA_DIR/identity.pem" ] && [ -z "$POLY_P2P_IDENTITY_B64" ]; then
    echo "  [!] No identity found. Generate with:"
    echo "      openssl genpkey -algorithm ED25519 > $DATA_DIR/identity.pem"
    echo "      Or set POLY_P2P_IDENTITY_B64 environment variable"
    exit 1
fi

# Start pulse.py for health checks
echo "  Launching Polygone Pulse..."
python3 /app/pulse.py &
sleep 1

# Start the P2P node
echo "  Launching Polygone Node..."
exec polygone-server "$@"
