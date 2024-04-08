#!/usr/bin/env bash

set -ex

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

if ! [[ -v TS_EXTRA_ARGS ]]; then
  echo "Warning: Environment variable TS_EXTRA_ARGS is not set"
fi

if ! [[ -v TS_STATE_DIR ]]; then
  echo "Info: Using default value for TS_STATE_DIR"
  export TS_STATE_DIR="/var/lib/tailscale"
fi

tailscale up --authkey=$TS_AUTHKEY $TS_EXTRA_ARGS

# Proton mail bridge listen only on 127.0.0.1 interface, we need to forward TCP traffic on SMTP and IMAP ports:
socat TCP-LISTEN:25,so-bindtodevice=tailscale0,reuseaddr,fork TCP:"$PROTON_BRIDGE_HOST":"$PROTON_BRIDGE_SMTP_PORT" &
socat TCP-LISTEN:143,so-bindtodevice=tailscale0,reuseaddr,fork TCP:"$PROTON_BRIDGE_HOST":"$PROTON_BRIDGE_IMAP_PORT" &

# Start a default Proton Mail Bridge on a fake tty, so it won't stop because of EOF
rm -f faketty
mkfifo faketty
cat faketty | /app/bridge --cli

echo "Done!"