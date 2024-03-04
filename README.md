# Proton Mail Bridge docker

A docker version of the [Proton mail Bridge](https://proton.me/mail/bridge) command line interface. It created a local SMTP server, so other docker containers can send emails via your Proton email account.

## Setup

See a list of [all Proton bridge commands available here](https://proton.me/support/bridge-cli-guide).

```bash
# Download the lastest version:
docker pull ghcr.io/videocurio/proton-mail-bridge:latest

# (Optional) It is recommended to setup a custom docker network for all of your containers to use, for DNS / network-alias resolution:
sudo docker network create --subnet 172.20.0.0/16 network20

# Launch it with this command to map TCP ports 12025 for SMTP and 12143 for IMAP on your local loopback:
docker run -d --name=protonmail_bridge -p 127.0.0.1:12025:1025/tcp -p 127.0.0.1:12143:1143/tcp --network network20 --restart=unless-stopped videocurio/proton-mail-bridge:latest
docker container logs protonmail_bridge

# Open a bash terminal on the current running container:
docker exec -it protonmail_bridge /bin/bash
# Login to your Proton account:
root@8972584f86d4:/protonmailbridge# ./bridge --cli
....
      Welcome to Proton Mail Bridge interactive shell
....
>>> info
No active accounts. Please add account to continue.

# Type help for a list of all commands:
>>> help
# Login to a Proton account, follow the instructions on screen:
>>> login

# Exit
>>> exit
root@8972584f86d4:/protonmailbridge# exit
```

## Developers notes

Build docker image, see: [Docker documentation](https://docs.docker.com/language/python/containerize/)
```bash
# Local tests:
docker build --tag=videocurio/proton-mail-bridge .
docker image ls videocurio/proton-mail-bridge
```

## Sources:

Made from [Debian 12 Go image](https://hub.docker.com/_/golang/) and [Proton Mail Bridge sources](https://github.com/ProtonMail/proton-bridge/tree/master).

An experimental [Alpine Linux](https://www.alpinelinux.org/) version for a small image base footprint is available in the alpine directory.