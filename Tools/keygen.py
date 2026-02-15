#!/usr/bin/env python3
"""
CelestialRecruiter - License Key Generator
Generates license keys using the same djb2 algorithm as Core/Tier.lua.

Usage:
    python keygen.py REC 20260323          # Recruteur key expiring March 23
    python keygen.py PRO 20260323          # Pro key expiring March 23
    python keygen.py LIFE                  # Lifetime key (never expires)
    python keygen.py REC --days 35         # Recruteur key, 35 days from now
    python keygen.py --batch members.csv   # Batch generate from CSV

Key format: CR-{TIER}-{YYYYMMDD}-{8hex_checksum}
Tier codes: REC (Recruteur 3EUR/mo), PRO (Elite 7EUR/mo), LIFE (Legendaire 20EUR)
"""

import sys
import argparse
from datetime import datetime, timedelta

# Must match Core/Tier.lua exactly
SALT = "CelestialRecruiter2026PlumePao"

TIER_CODES = {"REC", "PRO", "LIFE"}
TIER_LABELS = {
    "REC": "Le Recruteur (3\u20ac/mois)",
    "PRO": "L'Elite (7\u20ac/mois)",
    "LIFE": "Le Legendaire (20\u20ac)",
}


def djb2(s: str) -> str:
    """djb2 hash - identical to Tier.lua implementation."""
    h = 5381
    for c in s:
        h = ((h * 33) + ord(c)) % 4294967296
    return f"{h:08x}"


def compute_checksum(tier_code: str, date_str: str) -> str:
    return djb2(tier_code + date_str + SALT)


def generate_key(tier_code: str, date_str: str) -> str:
    """Generate a license key for the given tier and expiry date."""
    if tier_code not in TIER_CODES:
        raise ValueError(f"Invalid tier code: {tier_code}. Must be one of {TIER_CODES}")
    checksum = compute_checksum(tier_code, date_str)
    return f"CR-{tier_code}-{date_str}-{checksum}"


def generate_key_with_days(tier_code: str, days: int = 35) -> str:
    """Generate a key that expires N days from now."""
    if tier_code == "LIFE":
        return generate_key("LIFE", "99991231")
    expiry = datetime.now() + timedelta(days=days)
    return generate_key(tier_code, expiry.strftime("%Y%m%d"))


def validate_key(key: str) -> dict | None:
    """Validate a key and return its components, or None if invalid."""
    import re
    m = re.match(r"^CR-([A-Z]+)-(\d{8})-([0-9a-f]{8})$", key)
    if not m:
        return None
    tier_code, date_str, checksum = m.groups()
    if tier_code not in TIER_CODES:
        return None
    expected = compute_checksum(tier_code, date_str)
    if checksum != expected:
        return None
    expiry = int(date_str)
    today = int(datetime.now().strftime("%Y%m%d"))
    return {
        "key": key,
        "tier_code": tier_code,
        "tier_label": TIER_LABELS.get(tier_code, tier_code),
        "expiry": date_str,
        "expired": expiry < today,
        "days_left": (datetime.strptime(date_str, "%Y%m%d") - datetime.now()).days if expiry < 99990000 else 999999,
    }


def batch_generate(csv_path: str, days: int = 35) -> list[dict]:
    """
    Generate keys from a CSV file.
    CSV format: discord_id,tier_code
    Example:
        123456789012345678,REC
        987654321098765432,LIFE
    Returns list of {discord_id, tier_code, key}
    """
    import csv
    results = []
    with open(csv_path, "r") as f:
        reader = csv.reader(f)
        for row in reader:
            if len(row) < 2 or row[0].startswith("#"):
                continue
            discord_id = row[0].strip()
            tier_code = row[1].strip().upper()
            key = generate_key_with_days(tier_code, days)
            results.append({
                "discord_id": discord_id,
                "tier_code": tier_code,
                "key": key,
            })
    return results


def main():
    parser = argparse.ArgumentParser(description="CelestialRecruiter License Key Generator")
    parser.add_argument("tier", nargs="?", help="Tier code: REC, PRO, or LIFE")
    parser.add_argument("date", nargs="?", help="Expiry date YYYYMMDD (optional if --days used)")
    parser.add_argument("--days", type=int, default=35, help="Days until expiry (default: 35)")
    parser.add_argument("--batch", help="CSV file for batch generation (discord_id,tier_code)")
    parser.add_argument("--validate", help="Validate an existing key")
    parser.add_argument("--count", type=int, default=1, help="Number of keys to generate")
    args = parser.parse_args()

    # Validate mode
    if args.validate:
        result = validate_key(args.validate)
        if result:
            status = "EXPIRED" if result["expired"] else f"VALID ({result['days_left']} days left)"
            print(f"  Key:    {result['key']}")
            print(f"  Tier:   {result['tier_label']}")
            print(f"  Expiry: {result['expiry']}")
            print(f"  Status: {status}")
        else:
            print("  INVALID KEY")
        return

    # Batch mode
    if args.batch:
        results = batch_generate(args.batch, args.days)
        for r in results:
            print(f"{r['discord_id']},{r['tier_code']},{r['key']}")
        print(f"\n{len(results)} keys generated.", file=sys.stderr)
        return

    # Single key mode
    if not args.tier:
        parser.print_help()
        return

    tier = args.tier.upper()
    if tier not in TIER_CODES:
        print(f"Error: Invalid tier '{tier}'. Use REC, PRO, or LIFE.", file=sys.stderr)
        sys.exit(1)

    for _ in range(args.count):
        if tier == "LIFE":
            key = generate_key("LIFE", "99991231")
        elif args.date:
            key = generate_key(tier, args.date)
        else:
            key = generate_key_with_days(tier, args.days)

        info = validate_key(key)
        print(f"{key}")
        if args.count == 1 and info:
            print(f"  Tier:   {info['tier_label']}")
            print(f"  Expiry: {info['expiry']}")
            days = info['days_left']
            print(f"  Valid:  {'Forever' if days > 99999 else f'{days} days'}")


if __name__ == "__main__":
    main()
