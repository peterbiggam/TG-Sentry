#!/usr/bin/env bash
set -e

echo "=========================================="
echo "    Telegram Anti-Spam Sentry Setup       "
echo "=========================================="

# 1. Dependency & Permission Pre-flight Checks
if ! command -v docker &> /dev/null; then
    echo "[!] Error: Docker is not installed or not in PATH."
    echo "    Run: sudo apt update && sudo apt install -y docker.io docker-compose-v2"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo "[!] Error: Docker Compose plugin not found."
    echo "    Run: sudo apt install -y docker-compose-v2"
    exit 1
fi

# Check Docker socket connection permissions
if ! docker info &> /dev/null; then
    echo "[!] Error: Cannot connect to the Docker daemon (Permission Denied)."
    echo "    Your user is not in the active docker group session."
    echo "    Run the following, then execute this script again:"
    echo "        sudo usermod -aG docker \$USER && newgrp docker"
    exit 1
fi

# Check for docker-buildx plugin to prevent compose bake warnings
if ! docker buildx version &> /dev/null; then
    echo "[i] Optional: 'docker-buildx' is not installed."
    echo "    Installing it cleans up Docker Compose bake warnings: sudo apt install -y docker-buildx"
fi

# 2. Collect Telegram API Credentials if .env does not exist
if [ ! -f .env ]; then
    echo ""
    echo "--- Telegram API Configuration ---"
    echo "Obtain these from: https://my.telegram.org (API development tools)"
    read -rp "Enter API_ID: " api_id
    read -rp "Enter API_HASH: " api_hash
    read -rp "Auto-block senders after archiving? [y/N]: " auto_block_choice

    if [[ "$auto_block_choice" =~ ^[Yy]$ ]]; then
        auto_block_val="true"
    else
        auto_block_val="false"
    fi

    cat <<EOF > .env
API_ID=${api_id}
API_HASH=${api_hash}
AUTO_BLOCK=${auto_block_val}
EOF
    echo "[+] .env configuration saved."
else
    echo "[i] Existing .env detected. Preserving current credentials."
fi

# 3. Create persistent host directory
mkdir -p data/recon_photos

# 4. Generate .gitignore (Prevents committing credentials or session keys to Git)
cat << 'EOF' > .gitignore
# Environment & Secrets
.env

# Telethon Sessions & Recon Data
data/
*.session
*.session-journal
recon_photos/

# Python cache
__pycache__/
*.py[cod]
*$py.class
EOF
echo "[+] .gitignore created."

# 5. Generate requirements.txt
cat << 'EOF' > requirements.txt
telethon>=1.36.0
pillow>=10.4.0
python-dotenv>=1.0.1
EOF

# 6. Generate Dockerfile
cat << 'EOF' > Dockerfile
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY tg_recon_sentry.py .

RUN mkdir -p /app/data/recon_photos

CMD ["python", "tg_recon_sentry.py"]
EOF

# 7. Generate docker-compose.yml
cat << 'EOF' > docker-compose.yml
services:
  sentry:
    build: .
    container_name: tg_recon_sentry
    restart: unless-stopped
    env_file:
      - .env
    volumes:
      - ./data:/app/data
    stdin_open: true
    tty: true
EOF

# 8. Generate sentry application code
cat << 'EOF' > tg_recon_sentry.py
import os
import sys
from dotenv import load_dotenv
from telethon import TelegramClient, events
from telethon.tl.functions.messages import GetCommonChatsRequest
from telethon.tl.functions.users import GetFullUserRequest
from telethon.tl.functions.account import UpdateNotifySettingsRequest
from telethon.tl.functions.contacts import BlockRequest
from telethon.tl.types import InputPeerNotifySettings, User

load_dotenv()

API_ID_RAW = os.getenv("API_ID")
API_HASH = os.getenv("API_HASH")
AUTO_BLOCK = os.getenv("AUTO_BLOCK", "false").strip().lower() == "true"

if not API_ID_RAW or not API_HASH:
    print("[ERROR] API_ID and API_HASH must be configured in .env")
    sys.exit(1)

API_ID = int(API_ID_RAW)
DATA_DIR = "/app/data"
SESSION_PATH = os.path.join(DATA_DIR, "personal_sentry_session")
DOWNLOAD_DIR = os.path.join(DATA_DIR, "recon_photos")
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

client = TelegramClient(SESSION_PATH, API_ID, API_HASH)

def estimate_account_age(user_id: int) -> str:
    if user_id < 1_000_000_000:
        return "Legacy Account (Pre-2020)"
    elif user_id < 2_000_000_000:
        return "~2020 - 2021"
    elif user_id < 5_000_000_000:
        return "~2021 - 2022"
    elif user_id < 6_500_000_000:
        return "~2022 - 2023"
    elif user_id < 7_500_000_000:
        return "~2024 - 2025"
    else:
        return "Very Recent / Fresh Burner Account (2025-2026)"

@client.on(events.NewMessage(incoming=True, func=lambda e: e.is_private))
async def direct_message_sentry(event):
    sender = await event.get_sender()

    if not isinstance(sender, User) or sender.is_self:
        return

    # Whitelist all saved personal contacts
    if sender.contact:
        return

    sender_id = sender.id
    first_name = sender.first_name or ""
    last_name = sender.last_name or ""
    full_name = f"{first_name} {last_name}".strip() or "N/A"
    username = f"@{sender.username}" if sender.username else "None"
    phone = sender.phone if sender.phone else "Hidden"
    msg_text = event.message.raw_text or "[Non-text media]"

    print(f"\n[!] Intercepted unsolicited DM from: {full_name} (ID: {sender_id})")

    # Recon data collection
    bio = "None"
    dc_id = "Unknown"
    try:
        full_user_data = await client(GetFullUserRequest(sender))
        bio = full_user_data.full_user.about or "None"
        if sender.photo:
            dc_id = getattr(sender.photo, "dc_id", "Unknown")
    except Exception as e:
        print(f"Failed user lookup: {e}")

    # Mutual groups analysis
    mutual_groups = []
    try:
        common_chats = await client(GetCommonChatsRequest(user_id=sender_id, max_id=0, limit=100))
        for chat in common_chats.chats:
            title = getattr(chat, "title", "Unknown")
            username_chat = f" (@{chat.username})" if getattr(chat, "username", None) else ""
            mutual_groups.append(f"{title}{username_chat}")
    except Exception as e:
        mutual_groups.append(f"Lookup error: {e}")

    mutual_str = "\n".join([f"  • {g}" for g in mutual_groups]) if mutual_groups else "None (Direct query or scrape)"

    # Download profile photo locally for reverse-image OSINT
    avatar_file = None
    try:
        downloaded = await client.download_profile_photos(
            sender,
            file=os.path.join(DOWNLOAD_DIR, f"{sender_id}.jpg"),
            limit=1
        )
        if downloaded:
            avatar_file = downloaded if isinstance(downloaded, str) else downloaded[0]
    except Exception as e:
        print(f"Failed avatar download: {e}")

    flags = []
    if sender.scam: flags.append("FLAGGED_SCAM")
    if sender.fake: flags.append("FLAGGED_FAKE")
    if sender.premium: flags.append("TELEGRAM_PREMIUM")
    if sender.bot: flags.append("BOT_ACCOUNT")
    if sender.verified: flags.append("VERIFIED")
    flags_str = ", ".join(flags) if flags else "Normal / Unflagged"

    # Quarantine execution
    try:
        # Mute notifications permanently (Year 2038 epoch timestamp)
        await client(UpdateNotifySettingsRequest(
            peer=sender,
            settings=InputPeerNotifySettings(mute_until=2147483647)
        ))
        # Move conversation to Archive folder
        await client.edit_folder(sender, folder=1)
        # Clear unread badges
        await event.message.mark_read()

        if AUTO_BLOCK:
            await client(BlockRequest(id=sender_id))
            action_taken = "Muted, Archived, Marked Read, and BLOCKED"
        else:
            action_taken = "Muted, Archived, and Marked Read (Preserved for review)"
    except Exception as e:
        action_taken = f"Quarantine error: {e}"

    # Dispatch dossier to 'Saved Messages'
    report = (
        f"🚨 **SPAM SENTRY RECON DOSSIER** 🚨\n\n"
        f"**Target:** {full_name} ({username})\n"
        f"**User ID:** `{sender_id}`\n"
        f"**Phone:** `{phone}`\n"
        f"**Estimated Account Era:** {estimate_account_age(sender_id)}\n"
        f"**Hosting Data Center (DC):** DC{dc_id}\n"
        f"**Flags:** {flags_str}\n"
        f"**Bio / About:** {bio}\n\n"
        f"**Mutual Groups (Harvest Vector):**\n{mutual_str}\n\n"
        f"**Initial Message:**\n\"{msg_text}\"\n\n"
        f"**Action Taken:** {action_taken}"
    )

    await client.send_message("me", report, file=avatar_file)
    print(f"[+] Dossier successfully dispatched to Saved Messages for User ID: {sender_id}")

async def main():
    print("[*] Sentry daemon active. Monitoring inbound messages...")
    await client.run_until_disconnected()

if __name__ == "__main__":
    with client:
        client.loop.run_until_complete(main())
EOF

echo "[+] Application code, configuration, and Docker assets generated."

# 9. Build Docker Image
echo ""
echo "=== Step 1: Building Container Image ==="
docker compose build

# 10. Interactive Session Authentication
if [ ! -f data/personal_sentry_session.session ]; then
    echo ""
    echo "=== Step 2: Interactive Telegram Login ==="
    echo "Enter your phone number (+countrycode...), verification code, and 2FA password when prompted."
    echo "Once logged in and you see '[*] Sentry daemon active...', press Ctrl+C to proceed to daemon mode."
    echo ""
    docker compose run --rm sentry python tg_recon_sentry.py || true
else
    echo "[i] Existing session file found in data/. Skipping interactive auth."
fi

# 11. Launch Background Service
echo ""
echo "=== Step 3: Launching 24/7 Background Sentry ==="
docker compose up -d

echo ""
echo "=========================================="
echo "✓ Telegram Sentry is active and running!"
echo "  • Monitor live logs:   docker compose logs -f"
echo "  • Stop sentry:          docker compose down"
echo "  • Inspect recon media:  ls -lh data/recon_photos/"
echo "=========================================="