#!/usr/bin/env python3
"""
CelestialRecruiter - Patreon License Bot
Receives Patreon webhooks, generates license keys, sends them by email.

Flow:
    1. User pledges on Patreon
    2. Patreon fires webhook to this server
    3. Bot generates a license key matching the pledge tier
    4. Bot sends the key by email (SMTP)
    5. User enters /cr activate <key> in WoW

Setup:
    1. Set up Patreon webhook at https://www.patreon.com/portal/registration/register-webhooks
       - Triggers: members:pledge:create, members:pledge:update, members:pledge:delete
       - URL: https://your-server.com/patreon/webhook
    2. Create a Gmail App Password (or use any SMTP provider):
       - Google Account > Security > 2FA enabled > App Passwords > generate one
    3. Fill config.json (see config.example.json)
    4. Run: python patreon_license_bot.py

Requirements: flask
"""

import hashlib
import hmac
import json
import logging
import os
import smtplib
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from flask import Flask, request, jsonify

from keygen import generate_key_with_days, validate_key, TIER_LABELS

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

PATREON_WEBHOOK_SECRET = CONFIG.get("patreon_webhook_secret", "")

# SMTP config
SMTP_HOST = CONFIG.get("smtp_host", "smtp.gmail.com")
SMTP_PORT = CONFIG.get("smtp_port", 587)
SMTP_USER = CONFIG.get("smtp_user", "")      # e.g. celestialrecruiter@gmail.com
SMTP_PASSWORD = CONFIG.get("smtp_password", "")  # Gmail App Password
SMTP_FROM_NAME = CONFIG.get("smtp_from_name", "CelestialRecruiter")

# Patreon pledge amount (cents) -> tier code
PLEDGE_TO_TIER = {
    300: "REC",     # 3 EUR  -> Recruteur
    700: "PRO",     # 7 EUR  -> Elite
    2000: "LIFE",   # 20 EUR -> Legendaire (lifetime)
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
# License Log (persistent record of all keys)
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
# Email
# ---------------------------------------------------------------------------


def send_email(to_email: str, subject: str, body_html: str) -> bool:
    """Send an email via SMTP."""
    if not SMTP_USER or not SMTP_PASSWORD:
        log.error("SMTP not configured (smtp_user / smtp_password missing)")
        return False

    msg = MIMEMultipart("alternative")
    msg["From"] = f"{SMTP_FROM_NAME} <{SMTP_USER}>"
    msg["To"] = to_email
    msg["Subject"] = subject
    msg.attach(MIMEText(body_html, "html", "utf-8"))

    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USER, SMTP_PASSWORD)
            server.sendmail(SMTP_USER, to_email, msg.as_string())
        log.info(f"Email sent to {to_email}")
        return True
    except Exception as e:
        log.error(f"Failed to send email to {to_email}: {e}")
        return False


def build_license_email(key: str, tier_code: str, patron_name: str) -> tuple[str, str]:
    """Return (subject, html_body) for the license email."""
    tier_label = TIER_LABELS.get(tier_code, tier_code)
    info = validate_key(key)
    expiry = "Jamais (Lifetime)" if tier_code == "LIFE" else info["expiry"] if info else "?"

    subject = f"CelestialRecruiter - Votre licence {tier_label}"

    html = f"""\
<div style="font-family:Segoe UI,Arial,sans-serif;max-width:560px;margin:0 auto;
            background:#1a1814;color:#d4c5a9;padding:32px;border-radius:8px;
            border:1px solid #352c20;">

  <h1 style="color:#C9AA71;font-size:22px;margin:0 0 8px;">
    CelestialRecruiter
  </h1>
  <p style="color:#8B7340;font-size:13px;margin:0 0 24px;">
    Licence {tier_label}
  </p>

  <p>Merci <strong>{patron_name}</strong> pour ton soutien !</p>

  <p>Voici ta cl&eacute; de licence :</p>

  <div style="background:#0d0c0a;border:1px solid #352c20;border-radius:4px;
              padding:16px;text-align:center;margin:16px 0;">
    <code style="font-size:18px;color:#C9AA71;letter-spacing:1px;
                 user-select:all;">{key}</code>
  </div>

  <h3 style="color:#C9AA71;font-size:15px;">Comment activer :</h3>
  <ol style="padding-left:20px;line-height:1.8;">
    <li>Connecte-toi &agrave; World of Warcraft</li>
    <li>Ouvre le chat et tape :<br>
        <code style="background:#0d0c0a;padding:4px 8px;border-radius:3px;
                     color:#C9AA71;">/cr activate {key}</code></li>
    <li>Profite de toutes tes features !</li>
  </ol>

  <p style="font-size:13px;color:#6b5f4d;margin-top:24px;">
    Expiration : {expiry}<br>
    Support : <a href="https://discord.gg/3HwyEBaAQB"
                 style="color:#8B7340;">Discord</a>
  </p>
</div>
"""
    return subject, html


def build_cancellation_email(patron_name: str) -> tuple[str, str]:
    subject = "CelestialRecruiter - Abonnement annul\u00e9"
    html = f"""\
<div style="font-family:Segoe UI,Arial,sans-serif;max-width:560px;margin:0 auto;
            background:#1a1814;color:#d4c5a9;padding:32px;border-radius:8px;
            border:1px solid #352c20;">

  <h1 style="color:#C9AA71;font-size:22px;margin:0 0 16px;">
    CelestialRecruiter
  </h1>

  <p>Salut <strong>{patron_name}</strong>,</p>

  <p>Ton abonnement Patreon a &eacute;t&eacute; annul&eacute;.
     Ta licence restera active jusqu&rsquo;&agrave; sa date d&rsquo;expiration.</p>

  <p>Tes donn&eacute;es, templates et historique sont pr&eacute;serv&eacute;s.
     Tu peux te r&eacute;abonner &agrave; tout moment.</p>

  <p style="font-size:13px;color:#6b5f4d;margin-top:24px;">
    Merci d&rsquo;avoir soutenu le projet !
  </p>
</div>
"""
    return subject, html


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
    if amount_cents in PLEDGE_TO_TIER:
        return PLEDGE_TO_TIER[amount_cents]
    for threshold in sorted(PLEDGE_TO_TIER.keys(), reverse=True):
        if amount_cents >= threshold:
            return PLEDGE_TO_TIER[threshold]
    return None


def process_pledge_create(webhook_data: dict) -> dict:
    """Process a new pledge: generate key and send email."""
    data = webhook_data.get("data", {})
    attrs = data.get("attributes", {})
    amount_cents = (
        attrs.get("currently_entitled_amount_cents")
        or attrs.get("pledge_amount_cents", 0)
    )

    tier_code = map_pledge_to_tier(amount_cents)
    if not tier_code:
        return {"status": "skipped", "reason": f"Unknown pledge amount: {amount_cents} cents"}

    patron = extract_patron_info(webhook_data)
    key = generate_key_with_days(tier_code, MONTHLY_KEY_DAYS)

    log.info(
        f"Generated {tier_code} key for {patron['name']} "
        f"({patron['email']}, Patreon {patron['patreon_id']}): {key}"
    )

    save_license_entry({
        "timestamp": datetime.now().isoformat(),
        "event": "pledge_create",
        "patron_name": patron["name"],
        "patron_email": patron["email"],
        "patreon_id": patron["patreon_id"],
        "tier_code": tier_code,
        "amount_cents": amount_cents,
        "key": key,
    })

    # Send email
    email_sent = False
    if patron["email"]:
        subject, html = build_license_email(key, tier_code, patron["name"])
        email_sent = send_email(patron["email"], subject, html)

    return {
        "status": "ok",
        "tier": tier_code,
        "key": key,
        "email_sent": email_sent,
        **({"warning": "No email on Patreon profile"} if not patron["email"] else {}),
    }


def process_pledge_update(webhook_data: dict) -> dict:
    """Process a pledge update (tier change): generate new key."""
    return process_pledge_create(webhook_data)


def process_pledge_delete(webhook_data: dict) -> dict:
    """Process a pledge cancellation: notify user."""
    patron = extract_patron_info(webhook_data)

    save_license_entry({
        "timestamp": datetime.now().isoformat(),
        "event": "pledge_delete",
        "patron_name": patron["name"],
        "patreon_id": patron["patreon_id"],
    })

    if patron["email"]:
        subject, html = build_cancellation_email(patron["name"])
        send_email(patron["email"], subject, html)

    log.info(f"Pledge cancelled for {patron['name']} (Patreon {patron['patreon_id']})")
    return {"status": "ok", "event": "cancelled"}


# ---------------------------------------------------------------------------
# Flask App
# ---------------------------------------------------------------------------
app = Flask(__name__)


@app.route("/patreon/webhook", methods=["POST"])
def patreon_webhook():
    """Receive Patreon webhook events."""
    signature = request.headers.get("X-Patreon-Signature", "")
    if not verify_patreon_signature(request.data, signature):
        log.warning("Invalid Patreon webhook signature")
        return jsonify({"error": "Invalid signature"}), 403

    event_type = request.headers.get("X-Patreon-Event", "")
    log.info(f"Received Patreon event: {event_type}")

    try:
        webhook_data = request.get_json()
    except Exception as e:
        log.error(f"Failed to parse webhook JSON: {e}")
        return jsonify({"error": "Invalid JSON"}), 400

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
    Manual key generation + email delivery (admin only).
    Body: {"tier_code": "REC", "email": "user@example.com", "name": "John", "days": 45}
    """
    auth = request.headers.get("Authorization", "")
    admin_token = CONFIG.get("admin_token", "")
    if not admin_token or auth != f"Bearer {admin_token}":
        return jsonify({"error": "Unauthorized"}), 401

    data = request.get_json()
    tier_code = data.get("tier_code", "").upper()
    email = data.get("email", "")
    name = data.get("name", "Supporter")
    days = data.get("days", MONTHLY_KEY_DAYS)

    if tier_code not in {"REC", "PRO", "LIFE"}:
        return jsonify({"error": f"Invalid tier: {tier_code}"}), 400

    key = generate_key_with_days(tier_code, days)

    save_license_entry({
        "timestamp": datetime.now().isoformat(),
        "event": "manual_generate",
        "patron_name": name,
        "patron_email": email,
        "tier_code": tier_code,
        "key": key,
    })

    email_sent = False
    if email:
        subject, html = build_license_email(key, tier_code, name)
        email_sent = send_email(email, subject, html)

    return jsonify({"key": key, "tier": tier_code, "email_sent": email_sent}), 200


@app.route("/renew", methods=["POST"])
def batch_renew():
    """
    Batch renewal: regenerate and re-send keys for active members.
    Body: {"members": [{"email": "a@b.com", "tier_code": "REC", "name": "John"}, ...]}
    Run monthly via cron to keep active subscribers' keys fresh.
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
        email = member.get("email", "")
        name = member.get("name", "Supporter")

        if tier_code == "LIFE":
            continue  # Lifetime keys don't need renewal

        key = generate_key_with_days(tier_code, MONTHLY_KEY_DAYS)

        save_license_entry({
            "timestamp": datetime.now().isoformat(),
            "event": "batch_renew",
            "patron_name": name,
            "patron_email": email,
            "tier_code": tier_code,
            "key": key,
        })

        email_sent = False
        if email:
            subject, html = build_license_email(key, tier_code, name)
            email_sent = send_email(email, subject, html)

        results.append({"email": email, "tier": tier_code, "key": key, "email_sent": email_sent})

    return jsonify({"renewed": len(results), "results": results}), 200


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    port = CONFIG.get("license_bot_port", 5000)
    host = CONFIG.get("license_bot_host", "0.0.0.0")

    log.info(f"Starting CelestialRecruiter License Bot on {host}:{port}")
    log.info(f"SMTP: {'configured' if SMTP_USER else 'MISSING'}")
    log.info(f"Patreon secret: {'configured' if PATREON_WEBHOOK_SECRET else 'MISSING'}")

    app.run(host=host, port=port, debug=False)
