FROM golang:1.22-alpine AS build
LABEL authors="Charlton Trezevant"

# Install dependencies
RUN apk update
RUN apk add bash
RUN apk add make gcc g++ libc-dev musl musl-dev sed grep
RUN apk add git libsecret libsecret-dev pass curl lsof

# Build stage
WORKDIR /build/
RUN git clone https://github.com/ProtonMail/proton-bridge.git
WORKDIR /build/proton-bridge/

# Check out the latest stable release
RUN git fetch --all --tags && git checkout tags/v3.10.0 -b stable

# Resolves https://github.com/mattn/go-sqlite3/pull/1177
COPY fix_sqlite.sh /build/proton-bridge/
RUN chmod u+x /build/proton-bridge/fix_sqlite.sh
RUN /bin/bash -c '/build/proton-bridge/fix_sqlite.sh'

# make
RUN make build-nogui

# Working stage image
FROM golang:1.22-alpine
LABEL authors="Charlton Trezevant"
LABEL org.opencontainers.image.source="https://ghcr.io/nopehq/proton-bridge"

# Define arguments and env variables
# Indicate (NOT define) the ports/network interface really used by Proton bridge mail.
# It should be 1025/tcp and 1143/tcp but on some k3s instances it could be 1026 and 1144 (why ?)
# Launch `netstat -ltnp` on a running container to be sure.
ARG ENV_BRIDGE_SMTP_PORT=1025
ARG ENV_BRIDGE_IMAP_PORT=1143
ARG ENV_BRIDGE_HOST=127.0.0.1
ENV PROTON_BRIDGE_SMTP_PORT=$ENV_BRIDGE_SMTP_PORT
ENV PROTON_BRIDGE_IMAP_PORT=$ENV_BRIDGE_IMAP_PORT
ENV PROTON_BRIDGE_HOST=$ENV_BRIDGE_HOST

# Install dependencies
RUN apk update
RUN apk upgrade
RUN apk add --no-cache bash socat net-tools libsecret pass gpg gpg-agent ca-certificates 
RUN apk add --no-cache iptables iproute2 ip6tables iputils curl

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh \
    ; exit 0 # Ignore exit code from missing rc-update

# RUN rc-update add dbus
# RUN touch /run/openrc/softlevel
# RUN rc-service dbus start

# Copy executables made during previous stage
WORKDIR /app/
COPY --from=build /build/proton-bridge/bridge /app/
COPY --from=build /build/proton-bridge/proton-bridge /app/

# Install needed scripts and files
COPY entrypoint.sh /app/
RUN chmod u+x /app/entrypoint.sh
COPY gpgparams.txt /app/

# Expose SMTP and IMAP ports
# The entrypoint script will forward this ports to the ports really used by Proton mail bridge.
EXPOSE 25/tcp
EXPOSE 143/tcp

# Volume to save pass and bridge configurations/data
VOLUME /root

ENTRYPOINT ["/app/entrypoint.sh"]