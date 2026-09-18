# Telegram Anti-Spam Sentry & Recon Bot

A self-hosted, containerized MTProto userbot designed to protect personal Telegram accounts from unsolicited direct messages, romantic pig-butchering scams, and crypto spammers.

Without requiring a paid Telegram Business or Premium subscription, this service intercepts incoming messages from non-contacts, runs automated OSINT queries against the sender, quarantines the chat, and drops a full intelligence dossier directly into your **Saved Messages**.

---

## Features

* **Contact Whitelisting:** Any user saved in your Telegram contacts list bypasses inspection entirely and can DM you normally.
* **Automated Quarantine:**
  * Permanently mutes incoming notifications from the spammer.
  * Archives the chat folder to keep your primary inbox clean.
  * Marks incoming messages as read to eliminate unread notification badges.
  * *(Optional)* Automatically blocks the user account.
* **Automated OSINT & Threat Profiling:**
  * **Harvest Vector Discovery:** Queries Telegram for mutual groups to show exactly which public group the spammer scraped your account from.
  * **Account Age Heuristics:** Maps Telegram's sequential 64-bit user IDs to approximate registration dates (e.g., detecting fresh burner accounts).
  * **Risk Flags:** Checks for official Telegram flags (`scam`, `fake`, `premium`, `verified`).
  * **Hosting Data Center:** Identifies the data center (DC1–DC5) hosting the user's media.
  * **Avatar Extraction:** Automatically downloads the sender's profile picture for reverse-image search verification (detecting stolen model/influencer photos).
* **Saved Messages Dispatch:** Sends the full profile report and downloaded avatar straight to your private **Saved Messages** chat.
* **24/7 Dockerized Daemon:** Runs continuously in a lightweight container with persistent session storage.

---

## Prerequisites

* **Linux / Docker Host** (Ubuntu, Debian, Pop!_OS, WSL2, or a VPS)
* **Docker Engine** (`>= 20.10`) and **Docker Compose V2** (`docker compose`)
* **Telegram API Credentials** (`api_id` and `api_hash`) from [my.telegram.org](https://my.telegram.org)

### Quick Host Dependency Setup (Ubuntu / Debian)

```bash
# 1. Install Docker, Compose V2, and Buildx
sudo apt update
sudo apt install -y docker.io docker-compose-v2 docker-buildx

# 2. Add your user to the docker group (allows running without sudo)
sudo usermod -aG docker $USER
newgrp docker