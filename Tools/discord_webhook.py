#!/usr/bin/env python3
"""
CelestialRecruiter Discord Webhook Companion
Watches WoW SavedVariables and sends Discord webhooks for queued events

Requirements: pip install requests watchdog

Usage:
    python discord_webhook.py [--config config.json]
    python discord_webhook.py --test

Configuration:
    Create config.json with:
    {
        "savedvariables_path": "C:\\Path\\To\\WoW\\_retail_\\WTF\\Account\\ACCOUNT\\SavedVariables\\CelestialRecruiterDB.lua",
        "webhook_url": "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL",
        "check_interval": 5,
        "rate_limit_delay": 2
    }
"""

import json
import os
import sys
import time
import re
import logging
from pathlib import Path
from datetime import datetime, timezone
from typing import Dict, List, Optional, Any
from collections import deque

try:
    import requests
except ImportError:
    print("ERROR: requests library not installed")
    print("Install it with: pip install requests")
    sys.exit(1)

try:
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler
    WATCHDOG_AVAILABLE = True
except ImportError:
    WATCHDOG_AVAILABLE = False
    print("WARNING: watchdog library not installed (file watching disabled)")
    print("Install it with: pip install watchdog")


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler('discord_webhook.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class DiscordRateLimiter:
    """Rate limiter for Discord webhooks (30 requests per 60 seconds)"""

    def __init__(self, max_requests: int = 30, window_seconds: int = 60):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.request_times = deque()

    def wait_if_needed(self):
        """Block if rate limit would be exceeded"""
        for _ in range(10):  # Max 10 retries instead of unbounded recursion
            now = time.time()

            # Remove old requests outside the window
            while self.request_times and self.request_times[0] < now - self.window_seconds:
                self.request_times.popleft()

            # If at limit, wait until oldest request expires
            if len(self.request_times) >= self.max_requests:
                sleep_time = self.window_seconds - (now - self.request_times[0]) + 0.1
                if sleep_time > 0:
                    logger.warning(f"Rate limit reached, waiting {sleep_time:.1f}s")
                    time.sleep(sleep_time)
                    continue  # Re-check after sleep
            break

        # Record this request
        self.request_times.append(time.time())


class LuaParser:
    """Lua table parser for SavedVariables — with targeted queue extraction"""

    @staticmethod
    def parse_value(content: str, pos: int) -> tuple:
        """Parse a Lua value starting at position pos"""
        # Skip whitespace and comments
        while pos < len(content):
            if content[pos].isspace():
                pos += 1
            elif content[pos:pos+2] == '--':
                # Skip comment line
                while pos < len(content) and content[pos] != '\n':
                    pos += 1
            else:
                break

        if pos >= len(content):
            return None, pos

        # String (double or single quoted)
        if content[pos] in ('"', "'"):
            quote = content[pos]
            pos += 1
            value = []
            while pos < len(content) and content[pos] != quote:
                if content[pos] == '\\' and pos + 1 < len(content):
                    next_char = content[pos + 1]
                    if next_char == 'n':
                        value.append('\n')
                    elif next_char == 't':
                        value.append('\t')
                    elif next_char == '\\':
                        value.append('\\')
                    elif next_char == quote:
                        value.append(quote)
                    else:
                        value.append(next_char)
                    pos += 2
                else:
                    value.append(content[pos])
                    pos += 1
            return ''.join(value), pos + 1

        # Number
        if content[pos].isdigit() or content[pos] == '-':
            match = re.match(r'-?\d+(?:\.\d+)?', content[pos:])
            if match:
                num_str = match.group()
                value = float(num_str) if '.' in num_str else int(num_str)
                return value, pos + len(num_str)

        # Boolean
        if content[pos:pos+4] == 'true':
            return True, pos + 4
        if content[pos:pos+5] == 'false':
            return False, pos + 5

        # nil
        if content[pos:pos+3] == 'nil':
            return None, pos + 3

        # Table
        if content[pos] == '{':
            return LuaParser.parse_table(content, pos)

        # Unknown
        return None, pos + 1

    @staticmethod
    def parse_table(content: str, pos: int) -> tuple:
        """Parse a Lua table starting at position pos"""
        if content[pos] != '{':
            return None, pos

        pos += 1  # Skip '{'
        table = {}
        array = []
        is_array = True

        while pos < len(content):
            # Skip whitespace and comments
            while pos < len(content):
                if content[pos].isspace():
                    pos += 1
                elif content[pos:pos+2] == '--':
                    while pos < len(content) and content[pos] != '\n':
                        pos += 1
                else:
                    break

            if pos >= len(content):
                break

            # End of table
            if content[pos] == '}':
                pos += 1
                break

            # Key-value pair
            if content[pos] == '[':
                # Explicit key: [key] = value
                pos += 1
                key, pos = LuaParser.parse_value(content, pos)
                # Skip to '='
                while pos < len(content) and content[pos] != '=':
                    pos += 1
                pos += 1  # Skip '='
                value, pos = LuaParser.parse_value(content, pos)
                table[key] = value
                is_array = False
            elif re.match(r'[a-zA-Z_][a-zA-Z0-9_]*\s*=', content[pos:]):
                # Named key: key = value
                match = re.match(r'([a-zA-Z_][a-zA-Z0-9_]*)\s*=', content[pos:])
                key = match.group(1)
                pos += match.end()
                value, pos = LuaParser.parse_value(content, pos)
                table[key] = value
                is_array = False
            else:
                # Array element
                value, pos = LuaParser.parse_value(content, pos)
                array.append(value)

            # Skip comma
            while pos < len(content) and content[pos] in (',', ';', '\n', ' ', '\t'):
                pos += 1

        return (array if is_array and not table else table), pos

    @staticmethod
    def extract_discord_queue(content: str) -> list:
        """Fast extraction: find discordQueue section and parse only that.
        Avoids parsing the entire multi-MB SavedVariables file."""
        # Find the discordQueue key
        pattern = re.compile(r'\["discordQueue"\]\s*=\s*\{')
        match = pattern.search(content)
        if not match:
            return []

        # Position of the opening '{' for the queue table
        brace_start = match.end() - 1
        try:
            result, _ = LuaParser.parse_table(content, brace_start)
            if isinstance(result, list):
                return result
            elif isinstance(result, dict):
                # Shouldn't happen for an array, but handle gracefully
                return list(result.values())
            return []
        except Exception as e:
            logger.error(f"Failed to parse discordQueue: {e}")
            return []

    @staticmethod
    def parse_savedvariables(content: str) -> Dict[str, Any]:
        """Parse WoW SavedVariables file (full parse — use extract_discord_queue for speed)"""
        result = {}

        # Find all top-level variable assignments
        pattern = r'([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*{'
        for match in re.finditer(pattern, content):
            var_name = match.group(1)
            pos = match.start() + len(match.group(0)) - 1  # Position of '{'
            value, _ = LuaParser.parse_table(content, pos)
            result[var_name] = value

        return result


class DiscordWebhookSender:
    """Sends Discord webhooks with rich WoW-themed embeds + Raider.io data"""

    BOT_ICON = "https://wow.zamimg.com/images/wow/icons/large/achievement_guildperk_everybodysfriend.jpg"

    # WoW class -> (color, icon slug)
    CLASS_DATA = {
        "Guerrier": (0xC69B6D, "warrior"), "Guerriere": (0xC69B6D, "warrior"),
        "Paladin": (0xF48CBA, "paladin"), "Chasseur": (0xABD473, "hunter"),
        "Voleur": (0xFFF468, "rogue"), "Pretre": (0xFFFFFF, "priest"),
        "Chevalier de la mort": (0xC41E3A, "deathknight"),
        "Chaman": (0x0070DD, "shaman"), "Chamane": (0x0070DD, "shaman"),
        "Mage": (0x3FC7EB, "mage"), "Demoniste": (0x8788EE, "warlock"),
        "Moine": (0x00FF98, "monk"), "Druide": (0xFF7C0A, "druid"),
        "Chasseur de demons": (0xA330C9, "demonhunter"),
        "Evocateur": (0x33937F, "evoker"),
        "Warrior": (0xC69B6D, "warrior"), "Hunter": (0xABD473, "hunter"),
        "Rogue": (0xFFF468, "rogue"), "Priest": (0xFFFFFF, "priest"),
        "Death Knight": (0xC41E3A, "deathknight"), "Shaman": (0x0070DD, "shaman"),
        "Warlock": (0x8788EE, "warlock"), "Monk": (0x00FF98, "monk"),
        "Druid": (0xFF7C0A, "druid"), "Demon Hunter": (0xA330C9, "demonhunter"),
        "Evoker": (0x33937F, "evoker"),
    }

    PLAYER_EVENTS = {
        'guild_join', 'guild_leave', 'player_joined',
        'player_whispered', 'player_invited', 'player_blacklisted',
        'queue_added', 'queue_removed', 'whisper_received',
    }

    # Events worth enriching with Raider.io data
    ENRICH_EVENTS = {'guild_join', 'player_joined', 'guild_leave'}

    def __init__(self, webhook_url: str, rate_limiter: DiscordRateLimiter,
                 region: str = "eu"):
        self.webhook_url = webhook_url
        self.rate_limiter = rate_limiter
        self.region = region
        self._rio_cache: Dict[str, Dict[str, Any]] = {}  # name-realm -> raiderio data

    # ── helpers ──────────────────────────────────────────────────────

    @staticmethod
    def _fields_to_map(fields: list) -> Dict[str, str]:
        out = {}
        for f in fields:
            if isinstance(f, dict):
                out[f.get('name', '')] = str(f.get('value', ''))
        return out

    def _class_info(self, class_name: str):
        data = self.CLASS_DATA.get(class_name)
        if data:
            color, slug = data
            return color, f"https://wow.zamimg.com/images/wow/icons/large/classicon_{slug}.jpg"
        return None, None

    @staticmethod
    def _realm_to_slug(realm: str) -> str:
        """Convert WoW realm name to API slug: 'KhazModan' -> 'khaz-modan'"""
        slug = re.sub(r"(?<=[a-z])(?=[A-Z])", "-", realm)
        slug = slug.replace(" ", "-").replace("'", "").lower()
        return slug

    @staticmethod
    def _parse_player_realm(description: str) -> tuple:
        """Extract (name, realm) from embed description like '**Agniya-KhazModan**'"""
        m = re.search(r"\*\*([^*]+?)-([^*]+?)\*\*", description)
        if m:
            return m.group(1), m.group(2)
        return None, None

    # ── Raider.io enrichment ────────────────────────────────────────

    def _fetch_raiderio(self, name: str, realm: str) -> Dict[str, Any]:
        """Fetch ilvl, M+ score, raid prog, spec from Raider.io (cached)"""
        cache_key = f"{name}-{realm}"
        if cache_key in self._rio_cache:
            return self._rio_cache[cache_key]
        try:
            slug = self._realm_to_slug(realm)
            url = (
                f"https://raider.io/api/v1/characters/profile"
                f"?region={self.region}&realm={slug}&name={name}"
                f"&fields=gear,mythic_plus_scores_by_season:current,raid_progression"
            )
            resp = requests.get(url, timeout=5)
            if resp.status_code != 200:
                self._rio_cache[cache_key] = {}
                return {}
            d = resp.json()
            # Extract current raid prog (first key = current tier)
            raid_prog = ""
            rp = d.get("raid_progression", {})
            if rp:
                first_raid = next(iter(rp.values()), {})
                raid_prog = first_raid.get("summary", "")
            # M+ score
            seasons = d.get("mythic_plus_scores_by_season", [])
            mp_score = 0
            if seasons:
                mp_score = seasons[0].get("scores", {}).get("all", 0)
            result = {
                "ilvl": d.get("gear", {}).get("item_level_equipped"),
                "spec": d.get("active_spec_name", ""),
                "mp_score": mp_score,
                "raid_prog": raid_prog,
                "profile_url": d.get("profile_url", ""),
                "thumbnail": d.get("thumbnail_url", ""),
            }
            self._rio_cache[cache_key] = result
            return result
        except Exception as e:
            logger.debug(f"Raider.io lookup failed for {name}-{realm}: {e}")
            self._rio_cache[cache_key] = {}
            return {}

    # ── rich embed for player events ────────────────────────────────

    def _build_player_embed(self, event: Dict[str, Any]) -> dict:
        event_type = event.get('eventType', 'unknown')
        fm = self._fields_to_map(event.get('fields', []))
        ts = event.get('timestamp', time.time())

        class_name = fm.get('Classe', fm.get('Class', ''))
        class_color, class_icon = self._class_info(class_name)

        # ── Raider.io enrichment for join/leave ──
        rio = {}
        if event_type in self.ENRICH_EVENTS:
            pname, prealm = self._parse_player_realm(event.get('description', ''))
            if pname and prealm:
                rio = self._fetch_raiderio(pname, prealm)

        # ── description ──
        desc = event.get('description', '')

        # Join time
        join_time = datetime.fromtimestamp(ts, tz=timezone.utc)
        local_time = datetime.fromtimestamp(ts)  # local timezone
        desc += f"\n*{local_time.strftime('%d/%m/%Y a %H:%M')}*"

        # Identity line: Niv. 80 · Chamane (Restauration) · Draeneï · ilvl 615
        identity = []
        if fm.get('Niveau'):
            identity.append(f"Niv. **{fm['Niveau']}**")
        if class_name:
            spec = rio.get('spec', '')
            identity.append(f"**{class_name}**" + (f" ({spec})" if spec else ""))
        if fm.get('Race'):
            identity.append(fm['Race'])
        if rio.get('ilvl'):
            identity.append(f"ilvl **{rio['ilvl']}**")
        if identity:
            desc += '\n\n' + ' · '.join(identity)

        # Location
        if fm.get('Zone'):
            desc += f"\n{fm['Zone']}"
            if fm.get('Guilde') and event_type not in ('guild_join', 'player_joined'):
                desc += f" · <{fm['Guilde']}>"

        # M+ and raid prog (from Raider.io)
        if rio.get('mp_score') or rio.get('raid_prog'):
            prog = []
            if rio.get('mp_score'):
                prog.append(f"M+ **{rio['mp_score']:.0f}**")
            if rio.get('raid_prog'):
                prog.append(f"Raid: {rio['raid_prog']}")
            desc += '\n' + ' · '.join(prog)

        # Recruitment details
        recruit = []
        if fm.get('Source'):
            recruit.append(fm['Source'])
        if fm.get('Template'):
            recruit.append(f"Template: `{fm['Template']}`")
        if fm.get('Premier contact'):
            recruit.append(f"1er contact: {fm['Premier contact']}")
        if recruit:
            desc += '\n\n' + ' · '.join(recruit)

        # Conversion time
        if fm.get('Temps de conversion'):
            desc += f"\nConversion: **{fm['Temps de conversion']}**"

        # Status (for non-join events)
        if fm.get('Statut') and event_type not in ('guild_join', 'player_joined'):
            desc += f"\nStatut: **{fm['Statut']}**"

        # Opt-in
        if fm.get('Opt-in') and fm['Opt-in'] == 'Oui':
            desc += ' · Opt-in'

        # Reason (blacklist / remove)
        if fm.get('Raison'):
            desc += f"\nRaison: {fm['Raison']}"

        # Whisper message
        if fm.get('Message'):
            desc += f'\n\n> *{fm["Message"]}*'

        # Links (Raider.io + Armory)
        pname, prealm = self._parse_player_realm(event.get('description', ''))
        if pname and prealm:
            slug = self._realm_to_slug(prealm)
            links = []
            if rio.get('profile_url'):
                links.append(f"[Raider.io]({rio['profile_url']})")
            else:
                rio_url = f"https://raider.io/characters/{self.region}/{slug}/{pname}"
                links.append(f"[Raider.io]({rio_url})")
            armory = f"https://worldofwarcraft.blizzard.com/fr-fr/character/{self.region}/{slug}/{pname.lower()}"
            links.append(f"[Armurerie]({armory})")
            wl_url = f"https://www.warcraftlogs.com/character/{self.region}/{slug}/{pname}"
            links.append(f"[WarcraftLogs]({wl_url})")
            desc += '\n\n' + ' · '.join(links)

        # ── build embed ──
        embed = {
            "author": {
                "name": f"{event.get('icon', '')} {event.get('title', 'Event')}".strip(),
                "icon_url": class_icon or self.BOT_ICON,
            },
            "description": desc,
            "color": class_color or event.get('color', 3447003),
            "timestamp": datetime.fromtimestamp(ts, tz=timezone.utc).isoformat(),
            "footer": {
                "text": f"CelestialRecruiter · {event_type}",
                "icon_url": self.BOT_ICON,
            },
        }

        # Use Raider.io thumbnail if available, else class icon
        thumb = rio.get('thumbnail') or class_icon
        if thumb:
            embed["thumbnail"] = {"url": thumb}

        return embed

    # ── standard embed for system events ────────────────────────────

    def _build_system_embed(self, event: Dict[str, Any]) -> dict:
        event_type = event.get('eventType', 'unknown')
        embed = {
            "author": {
                "name": f"{event.get('icon', '')} {event.get('title', 'Event')}".strip(),
                "icon_url": self.BOT_ICON,
            },
            "description": event.get('description', ''),
            "color": event.get('color', 3447003),
            "timestamp": datetime.fromtimestamp(
                event.get('timestamp', time.time()), tz=timezone.utc
            ).isoformat(),
            "footer": {
                "text": f"CelestialRecruiter · {event_type}",
                "icon_url": self.BOT_ICON,
            },
        }
        fields = event.get('fields', [])
        if fields:
            embed['fields'] = [
                {"name": f.get('name', ''), "value": str(f.get('value', 'N/A')),
                 "inline": f.get('inline', False)}
                for f in fields
            ]
        return embed

    # ── send ────────────────────────────────────────────────────────

    def send_event(self, event: Dict[str, Any]) -> bool:
        try:
            self.rate_limiter.wait_if_needed()
            event_type = event.get('eventType', 'unknown')

            if event_type in self.PLAYER_EVENTS:
                embed = self._build_player_embed(event)
            else:
                embed = self._build_system_embed(event)

            payload = {
                "username": "CelestialRecruiter",
                "avatar_url": self.BOT_ICON,
                "embeds": [embed],
            }

            response = requests.post(self.webhook_url, json=payload, timeout=10)

            if response.status_code == 204:
                logger.info(f"Sent event: {event_type}")
                return True
            elif response.status_code == 429:
                retry_after = response.json().get('retry_after', 5)
                logger.warning(f"Discord rate limit hit, waiting {retry_after}s")
                time.sleep(retry_after)
                return False
            else:
                logger.error(f"Discord webhook failed: {response.status_code} - {response.text}")
                return False

        except requests.exceptions.Timeout:
            logger.error("Discord webhook timeout")
            return False
        except requests.exceptions.RequestException as e:
            logger.error(f"Discord webhook error: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error sending webhook: {e}")
            return False

    # ── summary mode ─────────────────────────────────────────────────

    # Event categories for grouping
    SUMMARY_CATEGORIES = [
        ("Guilde", {'guild_join', 'guild_leave', 'guild_promote', 'guild_demote'}),
        ("Recrutement", {'player_whispered', 'player_invited', 'player_joined',
                         'player_accepted', 'player_declined', 'whisper_received',
                         'queue_added', 'queue_removed', 'player_blacklisted'}),
        ("Scanner", {'scanner_started', 'scanner_stopped', 'scanner_complete',
                     'autorecruiter_started', 'autorecruiter_stopped',
                     'autorecruiter_complete'}),
        ("Alertes", {'limit_reached', 'error_alert', 'daily_summary',
                     'session_summary'}),
    ]

    def _enrich_player_line(self, event: Dict[str, Any]) -> str:
        """Build a rich line for a player event with class, ilvl, armory link"""
        fm = self._fields_to_map(event.get('fields', []))
        desc = event.get('description', '')
        icon = event.get('icon', '')
        event_type = event.get('eventType', '')

        pname, prealm = self._parse_player_realm(desc)
        if not pname or not prealm:
            # Fallback: just return basic info
            short_desc = desc.replace('\n', ' ')
            if len(short_desc) > 120:
                short_desc = short_desc[:117] + '...'
            return f"{icon} {short_desc}"

        # Build identity parts
        class_name = fm.get('Classe', fm.get('Class', ''))
        level = fm.get('Niveau', fm.get('Level', ''))
        _, class_icon = self._class_info(class_name)

        # Raider.io enrichment for join/leave events
        rio = {}
        if event_type in self.ENRICH_EVENTS:
            rio = self._fetch_raiderio(pname, prealm)

        # Player name line
        slug = self._realm_to_slug(prealm)
        armory_url = f"https://worldofwarcraft.blizzard.com/fr-fr/character/{self.region}/{slug}/{pname.lower()}"

        # Build identity: Niv. 80 · Mage · ilvl 615
        identity = []
        if level:
            identity.append(f"Niv. {level}")
        if class_name:
            spec = rio.get('spec', '')
            identity.append(f"{class_name}" + (f" ({spec})" if spec else ""))
        if rio.get('ilvl'):
            identity.append(f"ilvl {rio['ilvl']}")

        # Build links
        links = [f"[Armurerie]({armory_url})"]
        if rio.get('profile_url'):
            links.append(f"[Raider.io]({rio['profile_url']})")
        else:
            rio_url = f"https://raider.io/characters/{self.region}/{slug}/{pname}"
            links.append(f"[Raider.io]({rio_url})")

        # Compose line
        line = f"{icon} [**{pname}-{prealm}**]({armory_url})"
        if identity:
            line += f"\n> {' · '.join(identity)}"

        # Recruitment info
        recruit_parts = []
        if fm.get('Source'):
            recruit_parts.append(fm['Source'])
        if fm.get('Temps de conversion'):
            recruit_parts.append(f"Conv: **{fm['Temps de conversion']}**")
        # Extract recruiter from description
        recruiter_match = re.search(r"Recrute par \*\*([^*]+)\*\*", desc)
        if recruiter_match:
            recruit_parts.append(f"par **{recruiter_match.group(1)}**")

        if recruit_parts:
            line += f"\n> {' · '.join(recruit_parts)}"

        # M+ and raid progression
        prog_parts = []
        if rio.get('mp_score') and rio['mp_score'] > 0:
            prog_parts.append(f"M+ {rio['mp_score']:.0f}")
        if rio.get('raid_prog'):
            prog_parts.append(rio['raid_prog'])
        if prog_parts:
            line += f"\n> {' · '.join(prog_parts)}"

        line += f"\n> {' · '.join(links)}"

        return line

    def _build_summary_embed(self, events: List[Dict[str, Any]]) -> dict:
        """Build a clean summary embed grouping all events by category
        with armory links and Raider.io enrichment for player events."""

        # Group events by category
        categorized: Dict[str, List[Dict[str, Any]]] = {}
        uncategorized: List[Dict[str, Any]] = []

        for event in events:
            et = event.get('eventType', 'unknown')
            placed = False
            for cat_name, cat_types in self.SUMMARY_CATEGORIES:
                if et in cat_types:
                    categorized.setdefault(cat_name, []).append(event)
                    placed = True
                    break
            if not placed:
                uncategorized.append(event)

        # Build description with sections
        description_parts = []
        first_thumbnail = None  # First player thumbnail for embed

        for cat_name, cat_types in self.SUMMARY_CATEGORIES:
            cat_events = categorized.get(cat_name, [])
            if not cat_events:
                continue

            section_lines = [f"__**{cat_name}**__ ({len(cat_events)})"]

            for ev in cat_events:
                et = ev.get('eventType', '')

                # Player events get rich formatting with armory links
                if et in self.PLAYER_EVENTS:
                    line = self._enrich_player_line(ev)
                    section_lines.append(line)

                    # Capture first player thumbnail (already fetched in _enrich_player_line)
                    if first_thumbnail is None:
                        pn, pr = self._parse_player_realm(ev.get('description', ''))
                        if pn and pr:
                            key = f"{pn}-{pr}"
                            if key in self._rio_cache:
                                if self._rio_cache[key].get('thumbnail'):
                                    first_thumbnail = self._rio_cache[key]['thumbnail']
                else:
                    # System events: simple formatting
                    icon = ev.get('icon', '')
                    title = ev.get('title', ev.get('eventType', '?'))
                    desc = ev.get('description', '')
                    if len(desc) > 80:
                        desc = desc[:77] + '...'
                    fields = ev.get('fields', [])
                    line = f"{icon} **{title}**"
                    if desc:
                        line += f"\n> {desc}"
                    # Inline field values
                    if fields:
                        field_parts = [f"{f.get('name', '')}: **{f.get('value', '')}**"
                                       for f in fields[:4] if isinstance(f, dict)]
                        if field_parts:
                            line += f"\n> {' · '.join(field_parts)}"
                    section_lines.append(line)

            description_parts.append('\n\n'.join(section_lines))

        if uncategorized:
            lines = [f"__**Autres**__ ({len(uncategorized)})"]
            for ev in uncategorized:
                icon = ev.get('icon', '')
                title = ev.get('title', ev.get('eventType', '?'))
                lines.append(f"{icon} {title}")
            description_parts.append('\n\n'.join(lines))

        description = '\n\n'.join(description_parts)

        # Truncate if too long for Discord (max 4096 chars)
        if len(description) > 3900:
            description = description[:3900] + '\n\n*... (tronque)*'

        # Time range
        timestamps = [e.get('timestamp', 0) for e in events if e.get('timestamp')]
        ts_min = min(timestamps) if timestamps else time.time()
        ts_max = max(timestamps) if timestamps else time.time()

        time_min = datetime.fromtimestamp(ts_min)
        time_max = datetime.fromtimestamp(ts_max)

        # Date display
        date_str = time_min.strftime('%d/%m/%Y')
        time_range = f"{time_min.strftime('%H:%M')} — {time_max.strftime('%H:%M')}"

        embed = {
            "author": {
                "name": f"Resume CelestialRecruiter",
                "icon_url": self.BOT_ICON,
            },
            "title": f"{len(events)} evenement{'s' if len(events) > 1 else ''} · {date_str}",
            "description": description,
            "color": 0xC9AA71,  # CelestialRecruiter gold
            "timestamp": datetime.fromtimestamp(ts_max, tz=timezone.utc).isoformat(),
            "footer": {
                "text": f"CelestialRecruiter · {time_range}",
                "icon_url": self.BOT_ICON,
            },
        }

        # Use first player thumbnail or bot icon
        if first_thumbnail:
            embed["thumbnail"] = {"url": first_thumbnail}

        return embed

    def send_summary(self, events: List[Dict[str, Any]]) -> bool:
        """Send a summary embed grouping multiple events into one message"""
        self._rio_cache.clear()  # Fresh cache per summary batch
        try:
            self.rate_limiter.wait_if_needed()

            embed = self._build_summary_embed(events)

            payload = {
                "username": "CelestialRecruiter",
                "avatar_url": self.BOT_ICON,
                "embeds": [embed],
            }

            response = requests.post(self.webhook_url, json=payload, timeout=10)

            if response.status_code == 204:
                logger.info(f"Sent summary with {len(events)} events")
                return True
            elif response.status_code == 429:
                retry_after = response.json().get('retry_after', 5)
                logger.warning(f"Discord rate limit hit, waiting {retry_after}s")
                time.sleep(retry_after)
                return False
            else:
                logger.error(f"Discord webhook failed: {response.status_code} - {response.text}")
                return False

        except requests.exceptions.Timeout:
            logger.error("Discord webhook timeout (summary)")
            return False
        except requests.exceptions.RequestException as e:
            logger.error(f"Discord webhook error (summary): {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error sending summary webhook: {e}")
            return False


class SavedVariablesWatcher(FileSystemEventHandler):
    """Watches SavedVariables file for changes"""

    def __init__(self, callback):
        self.callback = callback
        self.last_modified = 0
        self.debounce_delay = 1  # seconds

    def on_modified(self, event):
        if event.is_directory:
            return

        # Debounce: WoW may write the file multiple times
        now = time.time()
        if now - self.last_modified < self.debounce_delay:
            return

        self.last_modified = now
        self.callback()


class DiscordWebhookBot:
    """Main bot that processes Discord queue"""

    def __init__(self, config_path: str):
        self.config = self.load_config(config_path)
        self.rate_limiter = DiscordRateLimiter(
            max_requests=30,
            window_seconds=60
        )
        self.sender = DiscordWebhookSender(
            self.config['webhook_url'],
            self.rate_limiter,
            region=self.config.get('region', 'eu')
        )
        self.summary_mode = self.config.get('summary_mode', True)
        self.last_processed_timestamp = 0
        self.savedvariables_path = Path(self.config['savedvariables_path'])
        self._last_mtime = 0  # Track file modification time to avoid re-parsing unchanged files

        # Load last processed timestamp from state file
        self.state_file = Path('discord_webhook_state.json')
        self.load_state()

    def load_config(self, config_path: str) -> Dict[str, Any]:
        """Load configuration from file"""
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)

            # Validate required fields
            required = ['savedvariables_path', 'webhook_url']
            for field in required:
                if field not in config:
                    raise ValueError(f"Missing required config field: {field}")

            # Set defaults
            config.setdefault('check_interval', 5)
            config.setdefault('rate_limit_delay', 2)

            return config

        except FileNotFoundError:
            logger.error(f"Config file not found: {config_path}")
            sys.exit(1)
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in config file: {e}")
            sys.exit(1)

    def load_state(self):
        """Load last processed timestamp from state file"""
        if self.state_file.exists():
            try:
                with open(self.state_file, 'r') as f:
                    state = json.load(f)
                    self.last_processed_timestamp = state.get('last_processed_timestamp', 0)
                    logger.info(f"Loaded state: last_processed_timestamp={self.last_processed_timestamp}")
            except Exception as e:
                logger.warning(f"Failed to load state file: {e}")

    def save_state(self):
        """Save last processed timestamp to state file"""
        try:
            with open(self.state_file, 'w') as f:
                json.dump({
                    'last_processed_timestamp': self.last_processed_timestamp
                }, f, indent=2)
        except Exception as e:
            logger.error(f"Failed to save state file: {e}")

    def extract_queue(self) -> Optional[list]:
        """Extract only the discordQueue from SavedVariables (fast, targeted parse)"""
        try:
            if not self.savedvariables_path.exists():
                logger.warning(f"SavedVariables file not found: {self.savedvariables_path}")
                return None

            # Check file modification time — skip if unchanged
            try:
                mtime = self.savedvariables_path.stat().st_mtime
            except OSError:
                mtime = 0

            if mtime == self._last_mtime:
                return None  # File unchanged, skip
            self._last_mtime = mtime

            with open(self.savedvariables_path, 'r', encoding='utf-8') as f:
                content = f.read()

            queue = LuaParser.extract_discord_queue(content)
            return queue

        except PermissionError:
            logger.debug("SavedVariables file locked (WoW writing), will retry")
            return None
        except Exception as e:
            logger.error(f"Error reading SavedVariables: {e}")
            return None

    def process_queue(self):
        """Process Discord event queue"""
        try:
            queue = self.extract_queue()
            if not queue:
                return

            # Filter events newer than last processed
            pending_events = [
                event for event in queue
                if isinstance(event, dict) and event.get('timestamp', 0) > self.last_processed_timestamp
            ]

            if not pending_events:
                return

            # Sort by timestamp to process in order
            pending_events.sort(key=lambda e: e.get('timestamp', 0))

            logger.info(f"Processing {len(pending_events)} pending events (summary_mode={self.summary_mode})")

            # Summary mode: group all events into one embed
            if self.summary_mode and len(pending_events) > 1:
                try:
                    success = self.sender.send_summary(pending_events)
                except Exception as e:
                    logger.error(f"Exception sending summary: {e}")
                    success = False

                if success:
                    self.last_processed_timestamp = max(
                        e.get('timestamp', 0) for e in pending_events
                    )
                    self.save_state()
                else:
                    logger.warning("Summary send failed, will retry")
            else:
                # Individual mode: send events one by one
                for event in pending_events:
                    try:
                        success = self.sender.send_event(event)
                    except Exception as e:
                        logger.error(f"Exception sending event {event.get('eventType', '?')}: {e}")
                        success = False

                    if success:
                        # Update last processed timestamp
                        event_ts = event.get('timestamp', 0)
                        if event_ts > self.last_processed_timestamp:
                            self.last_processed_timestamp = event_ts
                        self.save_state()

                        # Add delay between webhooks
                        time.sleep(self.config['rate_limit_delay'])
                    else:
                        # Stop processing on failure (will retry on next check)
                        logger.warning("Stopping queue processing due to send failure, will retry")
                        break
        except Exception as e:
            logger.error(f"Unexpected error in process_queue: {e}")

    def run_polling(self):
        """Run in polling mode (check file periodically)"""
        logger.info("Starting polling mode")
        logger.info(f"Watching: {self.savedvariables_path}")
        logger.info(f"Webhook: {self.config['webhook_url'][:50]}...")
        logger.info(f"Check interval: {self.config['check_interval']}s")
        logger.info(f"Summary mode: {self.summary_mode}")
        logger.info(f"Last processed timestamp: {self.last_processed_timestamp}")

        consecutive_errors = 0
        while True:
            try:
                self.process_queue()
                consecutive_errors = 0
                time.sleep(self.config['check_interval'])
            except KeyboardInterrupt:
                logger.info("Shutting down...")
                break
            except Exception as e:
                consecutive_errors += 1
                logger.error(f"Error in polling loop ({consecutive_errors}): {e}")
                # Back off on repeated errors to avoid spinning
                backoff = min(self.config['check_interval'] * consecutive_errors, 60)
                time.sleep(backoff)

    def run_watching(self):
        """Run in file watching mode (requires watchdog)"""
        if not WATCHDOG_AVAILABLE:
            logger.warning("Watchdog not available, falling back to polling mode")
            return self.run_polling()

        logger.info("Starting file watching mode")
        logger.info(f"Watching: {self.savedvariables_path}")
        logger.info(f"Webhook: {self.config['webhook_url'][:50]}...")

        # Process existing queue on startup
        self._last_mtime = 0  # Force parse on startup
        self.process_queue()

        # Watch for file changes
        def on_change():
            self._last_mtime = 0  # Reset mtime so extract_queue re-reads
            self.process_queue()

        event_handler = SavedVariablesWatcher(on_change)
        observer = Observer()
        observer.schedule(
            event_handler,
            str(self.savedvariables_path.parent),
            recursive=False
        )
        observer.start()

        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            logger.info("Shutting down...")
            observer.stop()
        observer.join()

    def run(self):
        """Run the bot (polling mode - most compatible)"""
        self._last_mtime = 0  # Force parse on first poll
        self.run_polling()


def test_webhook(webhook_url: str):
    """Send a test message to Discord webhook"""
    logger.info("Sending test webhook...")

    embed = {
        "title": "✅ Test Webhook",
        "description": "CelestialRecruiter Discord integration test successful!",
        "color": 3066993,  # Green
        "timestamp": datetime.now(tz=timezone.utc).isoformat(),
        "fields": [
            {
                "name": "Status",
                "value": "Connected",
                "inline": True
            },
            {
                "name": "Script Version",
                "value": "1.0.0",
                "inline": True
            }
        ],
        "footer": {
            "text": "CelestialRecruiter"
        }
    }

    payload = {
        "username": "CelestialRecruiter",
        "embeds": [embed]
    }

    try:
        response = requests.post(webhook_url, json=payload, timeout=10)
        if response.status_code == 204:
            logger.info("Test webhook sent successfully!")
            return True
        else:
            logger.error(f"Test webhook failed: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        logger.error(f"Test webhook error: {e}")
        return False


def create_default_config():
    """Create a default config.json template"""
    default_config = {
        "savedvariables_path": "C:\\Program Files (x86)\\World of Warcraft\\_retail_\\WTF\\Account\\YOUR_ACCOUNT\\SavedVariables\\CelestialRecruiterDB.lua",
        "webhook_url": "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN",
        "check_interval": 5,
        "rate_limit_delay": 2,
        "summary_mode": True
    }

    config_path = Path('config.json')
    if config_path.exists():
        logger.warning("config.json already exists, not overwriting")
        return

    with open(config_path, 'w') as f:
        json.dump(default_config, f, indent=2)

    logger.info("Created config.json template - please edit with your settings")


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(
        description='CelestialRecruiter Discord Webhook Companion'
    )
    parser.add_argument(
        '--config',
        default='config.json',
        help='Path to config file (default: config.json)'
    )
    parser.add_argument(
        '--test',
        action='store_true',
        help='Send a test webhook and exit'
    )
    parser.add_argument(
        '--create-config',
        action='store_true',
        help='Create a default config.json template'
    )

    args = parser.parse_args()

    if args.create_config:
        create_default_config()
        return

    if args.test:
        config_path = args.config
        if not Path(config_path).exists():
            logger.error(f"Config file not found: {config_path}")
            sys.exit(1)

        with open(config_path, 'r') as f:
            config = json.load(f)

        webhook_url = config.get('webhook_url')
        if not webhook_url or 'YOUR_WEBHOOK' in webhook_url:
            logger.error("Please configure your webhook_url in config.json")
            sys.exit(1)

        test_webhook(webhook_url)
        return

    # Run the bot
    bot = DiscordWebhookBot(args.config)
    bot.run()


if __name__ == '__main__':
    main()
