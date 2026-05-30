# VPS Server Bot

A Telegram bot for managing and monitoring a Linux VPS. Get daily health reports, trigger upgrades, check service status, and reboot — all from your phone.

## Example Report

```
🖥 Daily Server Report
2026-05-01 07:00 UTC

Uptime: 2 weeks, 1 day, 4 hours
Load: 0.02, 0.01, 0.00

💾 Disk: 12G used / 80G total (15%)
🧠 Memory: 312MB used / 1963MB total (1651MB free)
🔄 Swap: 0MB / 2047MB

⚙️ Services:
  • nginx: active
  • postgresql: active
  • fail2ban: active

🔒 Security:
  • SSH failed logins (24h): 3
  • Fail2ban total bans: 847

🌐 SSL Certificates:
  • mysite.com: ✅ 42d
  • shop.example.com: ✅ 60d
  • staging.example.com: ⚠️ 11d

📬 Contact Forms:
  • mysite.com: ✅
  • shop.example.com: ✅
  • staging.example.com: ✅

📦 Updates: 3 package(s) pending
🕐 Last upgrade: 2026-04-28 09:00:00
```

## Features

- **`/report`** — full server health report (disk, memory, load, services, SSL cert expiry, contact form health, pending updates)
- **`/status`** — quick service status snapshot
- **`/upgrade`** — run `apt upgrade` now (confirmation required)
- **`/reboot`** — reboot with a two-step confirmation and 60-second expiry
- **`/logs <service> [lines]`** — tail recent journal logs for a monitored service (default: 20 lines, max 50)
- **`/help`** — command list
- **Proactive alerts** — background monitoring fires a Telegram message when a service goes down or disk usage exceeds your threshold, and a follow-up when it recovers

The daily report runs automatically on a systemd timer (default: every day at 7AM UTC). A weekly full system upgrade also runs automatically (default: Sundays at 3AM UTC).

## Requirements

- Linux server with `systemd`
- Python 3 (stdlib only — no pip installs needed)
- `curl`, `openssl` on the server
- `fail2ban` (optional — security stats in reports will show `n/a` without it)
- A Telegram bot token from [@BotFather](https://t.me/BotFather)

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/dustinkznet/vps-bot.git
cd vps-bot
```

### 2. Create the env file

```bash
sudo mkdir -p /etc/bots
sudo cp server.env.example /etc/bots/server.env
sudo nano /etc/bots/server.env
```

Fill in your Telegram bot token, chat ID, and the lists you want monitored:

- `MONITORED_DOMAINS` — checked for SSL cert expiry and `/api/health` endpoint status
- `MONITORED_SERVICES` — systemd service names checked in `/status`, daily reports, and proactive alerts
- `DISK_WARN_PCT` — disk usage percentage that triggers a proactive alert (default: 80)
- `CERT_WARN_DAYS` — days before SSL expiry to show a warning in reports (default: 14)
- `ALERT_INTERVAL_MINUTES` — how often the bot checks services and disk in the background (default: 5)

### 3. First-time server setup

Create the runtime user, install dir, and state dir:

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin serverbot
sudo mkdir -p /opt/bots/server /var/lib/serverbot
sudo chown -R serverbot:serverbot /opt/bots/server /var/lib/serverbot
```

### 4. Deploy

From your local machine:

```bash
VPS_BOT_HOST=<your-host> ./deploy.sh
```

This copies the bot scripts, the systemd unit files (in `systemd/`), and the sudoers file (in `sudoers/`) into place, validates the sudoers file before installing it, reloads systemd, enables the daily-report and weekly-upgrade timers, and restarts the bot. Set the deploy target via the `VPS_BOT_HOST` environment variable — typically an SSH host alias from your `~/.ssh/config` (e.g. `VPS_BOT_HOST=my-server ./deploy.sh`). It is required; there is no default.

The deploy script is the only supported way to push changes — running individual `scp`s by hand is how config and code drift apart.

## Contact form health checks

The daily report checks `https://<domain>/api/health` for each domain in `MONITORED_DOMAINS`. This endpoint should return HTTP 200 when healthy. If a domain doesn't have this endpoint it will show `❌ (HTTP 404)` in the report — that's expected and not a problem. To skip the check for a domain, simply leave it out of `MONITORED_DOMAINS` and monitor it separately.

## Schedules

Two systemd timers run automatically:

- **`server-daily-report.timer`** — daily at 7AM UTC. Runs `daily-report.sh` and posts the health summary to Telegram.
- **`server-weekly-upgrade.timer`** — Sundays at 3AM UTC. Runs `weekly-upgrade.sh` (full `apt upgrade`).

To change a schedule, edit the `OnCalendar=` line in the corresponding timer file under `systemd/`, then `./deploy.sh`. See [systemd OnCalendar syntax](https://www.freedesktop.org/software/systemd/man/systemd.time.html) for format examples.

## Security notes

- The bot only responds to the `TELEGRAM_CHAT_ID` set in `server.env` — all other senders are silently ignored
- Tokens and credentials live in `/etc/bots/server.env`, which is root-owned and never committed to git
- Reboot and upgrade both require two-step confirmation with a 60-second expiry
- Proactive alert state is held in memory — if the bot restarts while a service is down, it will re-alert once on startup

## Updating

Edit files locally, then:

```bash
./deploy.sh
```

That's it. The deploy script handles file ownership, permissions, sudoers validation, and the systemd reload/restart.
