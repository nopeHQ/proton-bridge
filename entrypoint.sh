#!/usr/bin/env bash

set -ex

rm -f /root/.gnupg/public-keys.d/pubring.db.lock

# Check if the gpg key exist, if not created it. Should be run only on first launch.
if [ ! -d "/root/.password-store/" ]; then
  gpg --generate-key --batch /app/gpgparams.txt
  gpg --list-keys
  pass init ProtonMailBridge
fi

# Check if some env variables exist.
if ! [[ -v PROTON_BRIDGE_SMTP_PORT ]]; then
  echo "WARNING! Environment variable PROTON_BRIDGE_SMTP_PORT is not defined!"
fi

if ! [[ -v PROTON_BRIDGE_IMAP_PORT ]]; then
  echo "WARNING! Environment variable PROTON_BRIDGE_IMAP_PORT is not defined!"
fi

if ! [[ -v PROTON_BRIDGE_HOST ]]; then
  echo "WARNING! Environment variable PROTON_BRIDGE_HOST is not defined!"
fi

if ! [[ -v TS_AUTHKEY ]]; then
  echo "ERROR: Environment variable TS_AUTHKEY is not set"
  exit 1
fi

if ! [[ -v TAILSCALED_EXTRA_ARGS ]]; then
  export TAILSCALED_EXTRA_ARGS=""
fi

if ! [[ -v TS_EXTRA_ARGS ]]; then
  echo "Warning: Environment variable TS_EXTRA_ARGS is not set"
fi

if ! [[ -v TS_STATE_DIR ]]; then
  echo "Info: Using default value for TS_STATE_DIR"
  export TS_STATE_DIR="/var/lib/tailscale"
fi

tailscaled --tun=userspace-networking $TAILSCALED_EXTRA_ARGS &
sleep 3
tailscale up --authkey=$TS_AUTHKEY $TS_EXTRA_ARGS
sleep 3

# Serve TLS SMTP via Tailscale
tailscale serve --bg --tls-terminated-tcp 25 tcp://localhost:1025
tailscale serve --bg --tls-terminated-tcp 587 tcp://localhost:1025
tailscale serve --bg --tls-terminated-tcp 465 tcp://localhost:1025
tailscale serve --bg --tls-terminated-tcp 2525 tcp://localhost:1025

# Serve TLS IMAP via Tailscale
tailscale serve --bg --tls-terminated-tcp 143 tcp://localhost:1143
tailscale serve --bg --tls-terminated-tcp 585 tcp://localhost:1143
tailscale serve --bg --tls-terminated-tcp 993 tcp://localhost:1143

# Start a default Proton Mail Bridge on a fake tty, so it won't stop because of EOF
rm -f faketty
mkfifo faketty
cat faketty | /app/bridge --cli

echo "Done!"