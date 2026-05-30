#!/bin/bash
# Deploy vps_bot to the server.
# Stages files into ~/vps-bot-deploy/ on the server, then runs install.sh
# (which lives in that staging dir and handles sudo install + systemd reload).
#
# Usage: VPS_BOT_HOST=<your-host> ./deploy.sh
# Requires: ssh access to $HOST as a user with sudo.
#   <your-host> is typically an SSH host alias from your ~/.ssh/config.

set -euo pipefail

# Fail closed: no default host. The real deploy target is private infra and
# must not be baked into a public repo — set it via the environment instead.
HOST="${VPS_BOT_HOST:?set VPS_BOT_HOST to your deploy target (e.g. an ~/.ssh/config alias)}"

echo "==> Deploying to $HOST"

# Stage all files in the user's home dir on the server.
echo "==> Copying files to $HOST:~/vps-bot-deploy/"
ssh "$HOST" 'rm -rf ~/vps-bot-deploy && mkdir -p ~/vps-bot-deploy/systemd ~/vps-bot-deploy/sudoers'
scp telegram-bot.py daily-report.sh weekly-upgrade.sh install.sh "$HOST":~/vps-bot-deploy/
scp systemd/*.service systemd/*.timer "$HOST":~/vps-bot-deploy/systemd/
scp sudoers/serverbot "$HOST":~/vps-bot-deploy/sudoers/

# Run the installer with a normal interactive SSH (gets a real TTY, sudo prompt works).
echo "==> Running installer on $HOST (will prompt for sudo password)"
ssh -t "$HOST" 'bash ~/vps-bot-deploy/install.sh'

echo "==> Deploy complete."
