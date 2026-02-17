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

Keys are bound to a specific character (Name-Realm). The player name is
baked into the checksum so a key only validates on the intended character.
"""

import re
import sys
import argparse
from datetime import datetime, timedelta

# Must match Core/Tier.lua exactly
SALT = "CelestialRecruiter2026PlumePao"

# Player name validation: Name-Realm (supports French accented chars and realm spaces)
PLAYER_NAME_RE = re.compile(r"^[A-Za-z\u00C0-\u00FF]{2,12}-[A-Za-z\u00C0-\u00FF' ]{2,}$")

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


def compute_checksum(tier_code: str, date_str: str, player: str = "") -> str:
    """Checksum = djb2(tier + date + PLAYER_UPPER + salt)."""
    return djb2(tier_code + date_str + player.upper() + SALT)


def validate_player_name(player: str) -> bool:
    """Validate player name format: Name-Realm (e.g. Plume-Hyjal)."""
    if not player:
        return True  # Empty = unbound key
    return bool(PLAYER_NAME_RE.match(player))


def generate_key(tier_code: str, date_str: str, player: str = "") -> str:
    """Generate a license key for the given tier, expiry date, and player."""
    if tier_code not in TIER_CODES:
        raise ValueError(f"Invalid tier code: {tier_code}. Must be one of {TIER_CODES}")
    if player and not validate_player_name(player):
        raise ValueError(f"Invalid player name format: '{player}'. Expected: Name-Realm (e.g. Plume-Hyjal)")
    checksum = compute_checksum(tier_code, date_str, player)
    return f"CR-{tier_code}-{date_str}-{checksum}"


def generate_key_with_days(tier_code: str, days: int = 35, player: str = "") -> str:
    """Generate a key that expires N days from now, bound to a player."""
    if tier_code == "LIFE":
        return generate_key("LIFE", "99991231", player)
    expiry = datetime.now() + timedelta(days=days)
    return generate_key(tier_code, expiry.strftime("%Y%m%d"), player)


def validate_key(key: str, player: str = "") -> dict | None:
    """Validate a key and return its components, or None if invalid."""
    import re
    m = re.match(r"^CR-([A-Z]+)-(\d{8})-([0-9a-f]{8})$", key)
    if not m:
        return None
    tier_code, date_str, checksum = m.groups()
    if tier_code not in TIER_CODES:
        return None
    expected = compute_checksum(tier_code, date_str, player)
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
        "player": player,
    }


def batch_generate(csv_path: str, days: int = 35) -> list[dict]:
    """
    Generate keys from a CSV file.
    CSV format: discord_id,tier_code,player_name
    Example:
        123456789012345678,REC,Plume-Hyjal
        987654321098765432,LIFE,Arion-Dalaran
    Returns list of {discord_id, tier_code, player, key}
    """
    import csv
    results = []
    with open(csv_path, "r") as f:
        reader = csv.reader(f)
        for row in reader:
            if len(row) < 3 or row[0].startswith("#"):
                continue
            discord_id = row[0].strip()
            tier_code = row[1].strip().upper()
            player = row[2].strip()
            key = generate_key_with_days(tier_code, days, player)
            results.append({
                "discord_id": discord_id,
                "tier_code": tier_code,
                "player": player,
                "key": key,
            })
    return results


def main():
    parser = argparse.ArgumentParser(description="CelestialRecruiter License Key Generator")
    parser.add_argument("tier", nargs="?", help="Tier code: REC, PRO, or LIFE")
    parser.add_argument("date", nargs="?", help="Expiry date YYYYMMDD (optional if --days used)")
    parser.add_argument("--player", "-p", required=False, default="",
                        help="Player name (Name-Realm, e.g. Plume-Hyjal). Key only works for this character.")
    parser.add_argument("--days", type=int, default=35, help="Days until expiry (default: 35)")
    parser.add_argument("--batch", help="CSV file for batch generation (discord_id,tier_code,player)")
    parser.add_argument("--validate", help="Validate an existing key")
    parser.add_argument("--validate-player", dest="validate_player", default="",
                        help="Player name to validate against (used with --validate)")
    parser.add_argument("--count", type=int, default=1, help="Number of keys to generate")
    args = parser.parse_args()

    # Validate mode
    if args.validate:
        player = args.validate_player
        result = validate_key(args.validate, player)
        if result:
            status = "EXPIRED" if result["expired"] else f"VALID ({result['days_left']} days left)"
            print(f"  Key:    {result['key']}")
            print(f"  Tier:   {result['tier_label']}")
            print(f"  Player: {player if player else '(non lie)'}")
            print(f"  Expiry: {result['expiry']}")
            print(f"  Status: {status}")
        else:
            print("  INVALID KEY" + (f" (pour {player})" if player else ""))
        return

    # Batch mode
    if args.batch:
        results = batch_generate(args.batch, args.days)
        for r in results:
            print(f"{r['discord_id']},{r['tier_code']},{r['player']},{r['key']}")
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

    player = args.player
    if not player:
        print("ATTENTION: pas de --player, la clef ne sera liee a aucun personnage.", file=sys.stderr)

    for _ in range(args.count):
        if tier == "LIFE":
            key = generate_key("LIFE", "99991231", player)
        elif args.date:
            key = generate_key(tier, args.date, player)
        else:
            key = generate_key_with_days(tier, args.days, player)

        info = validate_key(key, player)
        print(f"{key}")
        if args.count == 1 and info:
            print(f"  Tier:   {info['tier_label']}")
            print(f"  Player: {player if player else '(non lie)'}")
            print(f"  Expiry: {info['expiry']}")
            days = info['days_left']
            print(f"  Valid:  {'Forever' if days > 99999 else f'{days} days'}")


if __name__ == "__main__":
    main()
