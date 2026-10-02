# _RUNBOOK — bots/vps_bot on the Mac

**Device:** Local Mac (source repo — deploys to the web server)
**Path:** `~/Dev/bots/vps_bot`
**Last updated:** 2026-10-02
**Schema:** 30

<!-- Real host, key, and deploy-path values live in ~/.infra/ and the gitignored CLAUDE.md — never here. -->

## What's Here
- `telegram-bot.py` — the server management bot (Telegram buttons + proactive alerts)
- `daily-report.sh` / `weekly-upgrade.sh` — timer-driven scripts
- `systemd/` — unit + timer files, tracked so the server can't drift from the repo
- `sudoers/serverbot` — the bot user's sudo rules
- `deploy.sh` / `install.sh` — config-as-code deploy (stage from the Mac, install on the server)
- `server.env.example` — template for the server-side env file (the real one is never committed)

## How It Runs
- Deploy: `./deploy.sh` from a real terminal (the server's sudo prompt needs a TTY)
- Runs as: systemd services + timers on the web server
- Restart / logs: `systemctl restart server-bot`, `journalctl -u server-bot -f`

## Notes
- This project predates the schema convention; the runbook was added 2026-10-02 so `/template-sync` has a stamp to work from.
