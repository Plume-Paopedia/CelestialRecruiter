#!/usr/bin/env python3
"""
CelestialRecruiter - Patreon License Bot
Receives Patreon webhooks, generates license keys, sends them via Discord DM.

Flow:
    1. User pledges on Patreon (must have Discord linked)
    2. Patreon fires webhook to this server
    3. Bot generates a license key for the user's tier
    4. Bot sends the key via Discord DM
    5. User enters /cr activate <key> in WoW

Setup:
    1. Create a Discord bot at https://discord.com/developers/applications
       - Enable "Message Content Intent" and "Server Members Intent"
       - Bot needs to be in your server (users must share a server with the bot for DMs)
    2. Set up Patreon webhook at https://www.patreon.com/portal/registration/register-webhooks
       - Triggers: members:pledge:create, members:pledge:update, members:pledge:delete
       - URL: https://your-server.com/patreon/webhook
    3. Fill config.json with discord_bot_token and patreon_webhook_secret
    4. Run: python patreon_license_bot.py

Requirements: flask, requests
"""

import hashlib
import hmac
import json
import logging
import os
import sys
from datetime import datetime, timedelta

import requests
from flask import Flask, request, jsonify

# Import key generator
from keygen import generate_key_with_days, generate_key, validate_key, TIER_LABELS

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(SCRIPT_DIR, "config.json")
LICENSE_LOG_PATH = os.path.join(SCRIPT_DIR, "license_log.json")

def load_config():
    with open(CONFIG_PATH, "r") as f:
        return json.load(f)

CONFIG = load_config()

DISCORD_BOT_TOKEN = CONFIG.get("discord_bot_token", "")
PATREON_WEBHOOK_SECRET = CONFIG.get("patreon_webhook_secret", "")
DISCORD_API = "https://discord.com/api/v10"

# Patreon pledge amount (cents) -> tier code
PLEDGE_TO_TIER = {
    300: "REC",    # 3 EUR  -> Recruteur
    700: "PRO",    # 7 EUR  -> Elite
    2000: "LIFE",  # 20 EUR -> Legendaire (lifetime)
}

# How many days a monthly key is valid (generous margin for Patreon billing)
MONTHLY_KEY_DAYS = 45

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(os.path.join(SCRIPT_DIR, "license_bot.log")),
        logging.StreamHandler(),
    ],
)
log = logging.getLogger("patreon_license_bot")

# ---------------------------------------------------------------------------
# License Log (persistent record of all generated keys)
# ---------------------------------------------------------------------------
def load_license_log() -> list:
    if os.path.exists(LICENSE_LOG_PATH):
        with open(LICENSE_LOG_PATH, "r") as f:
            return json.load(f)
    return []


def save_license_entry(entry: dict):
    entries = load_license_log()
    entries.append(entry)
    with open(LICENSE_LOG_PATH, "w") as f:
        json.dump(entries, f, indent=2)


# ---------------------------------------------------------------------------
# Discord DM
# ---------------------------------------------------------------------------
def discord_headers():
    return {
        "Authorization": f"Bot {DISCORD_BOT_TOKEN}",
        "Content-Type": "application/json",
    }


def send_discord_dm(discord_user_id: str, message: str) -> bool:
    """Send a DM to a Discord user via the bot."""
    # Step 1: Create/get DM channel
    r = requests.post(
        f"{DISCORD_API}/users/@me/channels",
        headers=discord_headers(),
        json={"recipient_id": discord_user_id},
    )
    if r.status_code != 200:
        log.error(f"Failed to create DM channel for {discord_user_id}: {r.status_code} {r.text}")
        return False

    channel_id = r.json()["id"]

    # Step 2: Send message
    r = requests.post(
        f"{DISCORD_API}/channels/{channel_id}/messages",
        headers=discord_headers(),
        json={"content": message},
    )
    if r.status_code not in (200, 201):
        log.error(f"Failed to send DM to {discord_user_id}: {r.status_code} {r.text}")
        return False

    log.info(f"DM sent to Discord user {discord_user_id}")
    return True


def format_license_dm(key: str, tier_code: str, patron_name: str) -> str:
    """Format the Discord DM message with the license key."""
    tier_label = TIER_LABELS.get(tier_code, tier_code)
    info = validate_key(key)
    expiry_text = "jamais (lifetime)" if tier_code == "LIFE" else info["expiry"] if info else "?"

    return (
        f"**CelestialRecruiter - Licence Activee**\n"
        f"\n"
        f"Merci {patron_name} pour ton soutien !\n"
        f"\n"
        f"Voici ta cle de licence **{tier_label}** :\n"
        f"```\n"
        f"{key}\n"
        f"```\n"
        f"\n"
        f"**Comment activer :**\n"
        f"1. Connecte-toi a WoW\n"
        f"2. Tape dans le chat : `/cr activate {key}`\n"
        f"3. Profite de toutes tes features !\n"
        f"\n"
        f"Expiration : {expiry_text}\n"
        f"Support : <https://discord.gg/3HwyEBaAQB>"
    )


def format_cancellation_dm(patron_name: str) -> str:
    return (
        f"**CelestialRecruiter - Abonnement annule**\n"
        f"\n"
        f"Salut {patron_name},\n"
        f"\n"
        f"Ton abonnement Patreon a ete annule. Ta licence restera active "
        f"jusqu'a sa date d'expiration.\n"
        f"\n"
        f"Tes donnees, templates et historique sont preserves. "
        f"Tu peux te reabonner a tout moment pour retrouver tes features.\n"
        f"\n"
        f"Merci d'avoir soutenu le projet !"
    )


# ---------------------------------------------------------------------------
# Patreon Webhook Processing
# ---------------------------------------------------------------------------
def verify_patreon_signature(payload: bytes, signature: str) -> bool:
    """Verify Patreon webhook signature (MD5 HMAC)."""
    if not PATREON_WEBHOOK_SECRET:
        log.warning("No Patreon webhook secret configured, skipping verification")
        return True
    expected = hmac.new(
        PATREON_WEBHOOK_SECRET.encode("utf-8"),
        payload,
        hashlib.md5,
    ).hexdigest()
    return hmac.compare_digest(expected, signature)


def extract_discord_id(webhook_data: dict) -> str | None:
    """Extract Discord user ID from Patreon webhook payload."""
    included = webhook_data.get("included", [])
    for resource in included:
        if resource.get("type") == "user":
            attrs = resource.get("attributes", {})
            social = attrs.get("social_connections", {})
            discord_info = social.get("discord")
            if discord_info and discord_info.get("user_id"):
                return discord_info["user_id"]
    return None


def extract_patron_info(webhook_data: dict) -> dict:
    """Extract patron name and email from webhook payload."""
    included = webhook_data.get("included", [])
    for resource in included:
        if resource.get("type") == "user":
            attrs = resource.get("attributes", {})
            return {
                "name": attrs.get("full_name", "Supporter"),
                "email": attrs.get("email", ""),
                "patreon_id": resource.get("id", ""),
            }
    return {"name": "Supporter", "email": "", "patreon_id": ""}


def map_pledge_to_tier(amount_cents: int) -> str | None:
    """Map Patreon pledge amount to tier code."""
    # Exact match first
    if amount_cents in PLEDGE_TO_TIER:
        return PLEDGE_TO_TIER[amount_cents]
    # Closest match (in case of currency conversion rounding)
    for threshold in sorted(PLEDGE_TO_TIER.keys(), reverse=True):
        if amount_cents >= threshold:
            return PLEDGE_TO_TIER[threshold]
    return None


def process_pledge_create(webhook_data: dict) -> dict:
    """Process a new pledge: generate key and send DM."""
    data = webhook_data.get("data", {})
    attrs = data.get("attributes", {})
    amount_cents = attrs.get("currently_entitled_amount_cents") or attrs.get("pledge_amount_cents", 0)

    tier_code = map_pledge_to_tier(amount_cents)
    if not tier_code:
        return {"status": "skipped", "reason": f"Unknown pledge amount: {amount_cents} cents"}

    discord_id = extract_discord_id(webhook_data)
    patron = extract_patron_info(webhook_data)

    # Generate license key
    key = generate_key_with_days(tier_code, MONTHLY_KEY_DAYS)
    log.info(f"Generated {tier_code} key for {patron['name']} (Patreon {patron['patreon_id']}): {key}")

    # Log the license
    save_license_entry({
        "timestamp": datetime.now().isoformat(),
        "event": "pledge_create",
        "patron_name": patron["name"],
        "patron_email": patron["email"],
        "patreon_id": patron["patreon_id"],
        "discord_id": discord_id,
        "tier_code": tier_code,
        "amount_cents": amount_cents,
        "key": key,
    })

    # Send Discord DM
    if discord_id:
        message = format_license_dm(key, tier_code, patron["name"])
        sent = send_discord_dm(discord_id, message)
        if sent:
            return {"status": "ok", "tier": tier_code, "key": key, "dm_sent": True}
        else:
            return {"status": "ok", "tier": tier_code, "key": key, "dm_sent": False,
                    "warning": "DM failed - check bot permissions or user privacy settings"}
    else:
        return {"status": "ok", "tier": tier_code, "key": key, "dm_sent": False,
                "warning": "No Discord ID linked on Patreon - key logged but not delivered"}


def process_pledge_update(webhook_data: dict) -> dict:
    """Process a pledge update (tier change): generate new key."""
    return process_pledge_create(webhook_data)


def process_pledge_delete(webhook_data: dict) -> dict:
    """Process a pledge cancellation: notify user."""
    discord_id = extract_discord_id(webhook_data)
    patron = extract_patron_info(webhook_data)

    save_license_entry({
        "timestamp": datetime.now().isoformat(),
        "event": "pledge_delete",
        "patron_name": patron["name"],
        "patreon_id": patron["patreon_id"],
        "discord_id": discord_id,
    })

    if discord_id:
        message = format_cancellation_dm(patron["name"])
        send_discord_dm(discord_id, message)

    log.info(f"Pledge cancelled for {patron['name']} (Patreon {patron['patreon_id']})")
    return {"status": "ok", "event": "cancelled"}


# ---------------------------------------------------------------------------
# Flask App
# ---------------------------------------------------------------------------
app = Flask(__name__)


@app.route("/patreon/webhook", methods=["POST"])
def patreon_webhook():
    """Receive Patreon webhook events."""
    # Verify signature
    signature = request.headers.get("X-Patreon-Signature", "")
    if not verify_patreon_signature(request.data, signature):
        log.warning("Invalid Patreon webhook signature")
        return jsonify({"error": "Invalid signature"}), 403

    # Parse event type
    event_type = request.headers.get("X-Patreon-Event", "")
    log.info(f"Received Patreon event: {event_type}")

    try:
        webhook_data = request.get_json()
    except Exception as e:
        log.error(f"Failed to parse webhook JSON: {e}")
        return jsonify({"error": "Invalid JSON"}), 400

    # Route by event type
    handlers = {
        "members:pledge:create": process_pledge_create,
        "members:pledge:update": process_pledge_update,
        "members:pledge:delete": process_pledge_delete,
    }

    handler = handlers.get(event_type)
    if not handler:
        log.info(f"Ignoring unhandled event type: {event_type}")
        return jsonify({"status": "ignored", "event": event_type}), 200

    result = handler(webhook_data)
    log.info(f"Event result: {result}")
    return jsonify(result), 200


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "service": "CelestialRecruiter License Bot"}), 200


@app.route("/generate", methods=["POST"])
def manual_generate():
    """
    Manual key generation endpoint (admin only).
    Body: {"tier_code": "REC", "discord_id": "123456", "patron_name": "John", "days": 45}
    """
    auth = request.headers.get("Authorization", "")
    admin_token = CONFIG.get("admin_token", "")
    if not admin_token or auth != f"Bearer {admin_token}":
        return jsonify({"error": "Unauthorized"}), 401

    data = request.get_json()
    tier_code = data.get("tier_code", "").upper()
    discord_id = data.get("discord_id", "")
    patron_name = data.get("patron_name", "Supporter")
    days = data.get("days", MONTHLY_KEY_DAYS)

    if tier_code not in {"REC", "PRO", "LIFE"}:
        return jsonify({"error": f"Invalid tier: {tier_code}"}), 400

    key = generate_key_with_days(tier_code, days)

    save_license_entry({
        "timestamp": datetime.now().isoformat(),
        "event": "manual_generate",
        "patron_name": patron_name,
        "discord_id": discord_id,
        "tier_code": tier_code,
        "key": key,
    })

    # Send DM if discord_id provided
    dm_sent = False
    if discord_id:
        message = format_license_dm(key, tier_code, patron_name)
        dm_sent = send_discord_dm(discord_id, message)

    return jsonify({"key": key, "tier": tier_code, "dm_sent": dm_sent}), 200


@app.route("/renew", methods=["POST"])
def batch_renew():
    """
    Batch renewal endpoint: regenerate and re-send keys for active members.
    Body: {"members": [{"discord_id": "123", "tier_code": "REC", "name": "John"}, ...]}
    Run this monthly via cron to keep active subscribers' keys fresh.
    """
    auth = request.headers.get("Authorization", "")
    admin_token = CONFIG.get("admin_token", "")
    if not admin_token or auth != f"Bearer {admin_token}":
        return jsonify({"error": "Unauthorized"}), 401

    data = request.get_json()
    members = data.get("members", [])
    results = []

    for member in members:
        tier_code = member.get("tier_code", "").upper()
        discord_id = member.get("discord_id", "")
        name = member.get("name", "Supporter")

        if tier_code == "LIFE":
            continue  # Lifetime keys don't need renewal

        key = generate_key_with_days(tier_code, MONTHLY_KEY_DAYS)

        save_license_entry({
            "timestamp": datetime.now().isoformat(),
            "event": "batch_renew",
            "patron_name": name,
            "discord_id": discord_id,
            "tier_code": tier_code,
            "key": key,
        })

        dm_sent = False
        if discord_id:
            message = format_license_dm(key, tier_code, name)
            dm_sent = send_discord_dm(discord_id, message)

        results.append({"discord_id": discord_id, "tier": tier_code, "key": key, "dm_sent": dm_sent})

    return jsonify({"renewed": len(results), "results": results}), 200


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    port = CONFIG.get("license_bot_port", 5000)
    host = CONFIG.get("license_bot_host", "0.0.0.0")

    log.info(f"Starting CelestialRecruiter License Bot on {host}:{port}")
    log.info(f"Discord bot token: {'configured' if DISCORD_BOT_TOKEN else 'MISSING'}")
    log.info(f"Patreon webhook secret: {'configured' if PATREON_WEBHOOK_SECRET else 'MISSING'}")

    app.run(host=host, port=port, debug=False)
