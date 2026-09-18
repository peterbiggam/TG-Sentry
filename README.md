# 🛡️ Telegram Anti-Spam Sentry & OSINT Recon Bot

A self-hosted, containerized MTProto userbot designed to protect personal Telegram accounts from unsolicited direct messages, romantic pig-butchering scams, and crypto spammers.

Without requiring a paid Telegram Business or Premium subscription, this service intercepts incoming messages from non-contacts, runs automated OSINT queries against the sender, quarantines the chat, and drops a full intelligence dossier directly into your **Saved Messages**.

---

## ✨ Features

* 📇 **Contact Whitelisting:** Any user saved in your Telegram contacts list bypasses inspection entirely and can DM you normally.
* 🛑 **Automated Quarantine:**
  * 🔇 Permanently mutes incoming notifications from the spammer.
  * 🗄️ Archives the chat folder to keep your primary inbox clean.
  * 👁️ Marks incoming messages as read to eliminate unread notification badges.
  * 🚫 *(Optional)* Automatically blocks the user account.
* 🕵️ **Automated OSINT & Threat Profiling:**
  * 🎯 **Harvest Vector Discovery:** Queries Telegram for mutual groups to show exactly which public group the spammer scraped your account from.
  * ⏳ **Account Age Heuristics:** Maps Telegram's sequential 64-bit user IDs to approximate registration dates (e.g., detecting fresh burner accounts).
  * 🚩 **Risk Flags:** Checks for official Telegram flags (`scam`, `fake`, `premium`, `verified`).
  * 🌐 **Hosting Data Center:** Identifies the data center (DC1–DC5) hosting the user's media.
  * 🖼️ **Avatar Extraction:** Automatically downloads the sender's profile picture for reverse-image search verification (detecting stolen model/influencer photos).
* 📨 **Saved Messages Dispatch:** Sends the full profile report and downloaded avatar straight to your private **Saved Messages** chat.
* 🐳 **24/7 Dockerized Daemon:** Runs continuously in a lightweight container with persistent session storage.

---

## 📋 Prerequisites

* 🐧 **Linux / Docker Host** (Ubuntu, Debian, Pop!_OS, WSL2, or a VPS)
* 📦 **Docker Engine** (`>= 20.10`) and **Docker Compose V2** (`docker compose`)
* 🔑 **Telegram API Credentials** (`api_id` and `api_hash`) from [my.telegram.org](https://my.telegram.org)

---

## ⚙️ Configure Service & User Permissions

Ensure Docker Engine, Docker Compose V2, and Buildx are installed, then configure service permissions so Docker commands can run without `sudo`:

```bash
# 1. Install Docker, Compose V2, and Buildx
sudo apt update
sudo apt install -y docker.io docker-compose-v2 docker-buildx

# 2. Enable and start the Docker daemon
sudo systemctl enable --now docker

# 3. Add your user to the docker group (allows running without sudo)
sudo usermod -aG docker $USER
newgrp docker
🔍 Verify Setup
Confirm that the Docker daemon is accessible and your user permissions are active:

Bash
docker --version
docker compose version
docker ps
🔑 Obtaining Telegram API Credentials
Because standard bots cannot read or manage direct messages on personal user accounts, this service connects via the MTProto Client API:

🌐 Open my.telegram.org in your web browser.

📱 Enter your phone number in full international format (e.g., +18315551234) and click Next.

💬 Telegram will dispatch a login code inside your official Telegram application (under the verified Telegram service notifications chat, not SMS). Enter this code and sign in.

🛠️ Click API development tools.

📝 Fill out the application registration form:

App title: AntiSpamSentry (or any label)

Short name: antispamsentry (alphanumeric, lowercase only)

Platform: Select Desktop

🚀 Click Create application.

📋 Copy your credentials:

App api_id: A 7- to 8-digit integer (e.g., 38953325).

App api_hash: A 32-character hexadecimal string (e.g., a03edcaf46faac62772286999472463c).

💡 Note: If my.telegram.org returns a generic red ERROR, disable browser ad-blockers or try an Incognito/Private browsing window.

🚀 Deployment & First-Time Authentication
1. Project Directory & Automated Setup Script
Create a working directory and create setup_sentry.sh:

Bash
mkdir -p tg-anti-spam-sentry && cd tg-anti-spam-sentry
nano setup_sentry.sh
2. Execute First-Time Authentication
Make the installer executable and launch it:

Bash
chmod +x setup_sentry.sh
./setup_sentry.sh
During the interactive setup:

📞 Enter your phone number in full international format (e.g., +18315551234).

📩 Enter the login confirmation code sent to your official Telegram app.

🔐 Enter your Two-Step Verification (2FA) cloud password if enabled on your account.

🛑 When you see [*] Sentry daemon active. Monitoring inbound messages..., press Ctrl + C.

🐳 The setup script will finalize your session file inside data/ and start the Docker container in detached background mode (-d).

🛠️ Day-to-Day Operations
Manage the background container using standard Docker Compose operations:

📜 Stream Live Activity Logs:

Bash
docker compose logs -f
🖼️ Inspect Harvested Profile Photos:

Bash
ls -lh data/recon_photos/
🔄 Restart the Container:

Bash
docker compose restart
🛑 Stop the Sentry Daemon:

Bash
docker compose down
⚙️ Modify Settings:
Edit the .env file (e.g., toggle AUTO_BLOCK=true or false), then recreate the container:

Bash
docker compose up -d --force-recreate
🔍 Threat & OSINT Breakdown
When an unsolicited direct message is intercepted, the sentry isolates the sender and dispatches an intelligence briefing directly into your Saved Messages inbox:

Plaintext
🚨 SPAM SENTRY RECON DOSSIER 🚨

Target: Chloe Bennett (@chloe_b_crypto)
User ID: 7894102941
Phone: Hidden
Estimated Account Era: Very Recent / Fresh Burner Account (2025-2026)
Hosting Data Center (DC): DC5
Flags: Normal / Unflagged
Bio / About: Financial Consultant 📈 | Crypto & Forex Enthusiast | Living Life 🌴

Mutual Groups (Harvest Vector):
  • Trading Signals Global (@tradingsignalsglobal)
  • Binance Whale Alerts (@binancewhalealerts)

Initial Message:
"Hi! Excuse me, are you living in California? You look very familiar :)"

Action Taken: Muted, Archived, Marked Read (Preserved for review)
🔬 Intelligence Vector Breakdown
🎯 Harvest Vector (Mutual Groups): Pig-butchering and romance scammers deploy bots to mass-scrape member lists from large public crypto, trading, and regional groups. The mutual groups section exposes the exact channel leaking your profile, enabling you to adjust group settings or exit the group entirely.

⏳ Account Age Estimation: Telegram assigns 64-bit user IDs in strict chronological order. Sequential IDs above 7,500,000,000 indicate accounts generated within recent months—a reliable indicator of disposable burner accounts used for social engineering.

🖼️ Avatar Analysis: Downloaded avatars stored in data/recon_photos/<USER_ID>.jpg can be dropped directly into reverse-image search engines (such as Google Lens or Yandex Images) to identify the original social media influencer or model from whom the photo was stolen.

🌐 Data Center (DC) Analysis: Reveals the regional data center hosting the profile's media assets (DC1/DC3: North America, DC2/DC4: Europe, DC5: Singapore/Asia), providing initial indicators regarding the operational infrastructure of the account.

🧯 Troubleshooting
⚠️ Docker Daemon Socket Permission Denied
If you encounter dial unix /var/run/docker.sock: connect: permission denied:

Bash
sudo usermod -aG docker $USER
newgrp docker
Verify access by running docker ps without sudo.

⚠️ Buildx Baking Warnings
If Docker Compose displays WARN[0000] Docker Compose is configured to build using Bake, but buildx isn't installed:

Bash
sudo apt install -y docker-buildx
⚠️ Authentication Code Not Received
Telegram dispatches MTProto client login codes directly through an official service chat notification within the Telegram app on your existing logged-in desktop or mobile devices—not through SMS. Check your active sessions for the login code.

⚠️ Two-Step Verification (2FA) Errors
If you have cloud password protection enabled and the prompt times out or fails, verify your password inside Settings > Privacy and Security > Two-Step Verification on your official Telegram client before attempting authentication again.

🔒 Session File Persistence & Security
Your session file (data/personal_sentry_session.session) contains active authentication tokens that grant full client access to your account.

🚫 Never commit this file or the data/ folder to GitHub.

🛡️ The included .gitignore file automatically excludes .env and data/ from version control tracking.