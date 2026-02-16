#!/usr/bin/env python3
"""
CelestialRecruiter AI Companion
Generates personalized recruitment messages and conversation responses using Claude API.
Communicates with the WoW addon via shared SavedVariables files.

Requirements: pip install anthropic watchdog

Usage:
    python ai_recruiter.py [--config config.json]
    python ai_recruiter.py --once    (single pass, no watch loop)

Flow:
    1. Read CelestialRecruiterDB.lua (contacts, queue, pending replies)
    2. Call Claude API to generate messages + responses
    3. Write CelestialRecruiterAI.lua (pre-generated content)
    4. Addon does ReloadUI() -> loads AI content -> uses it for whispers/replies
"""

import json
import os
import sys
import re
import time
import logging
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any

try:
    import anthropic
except ImportError:
    print("ERROR: anthropic library not installed")
    print("Install it with: pip install anthropic")
    sys.exit(1)

try:
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler
    WATCHDOG_AVAILABLE = True
except ImportError:
    WATCHDOG_AVAILABLE = False

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
LOG_FILE = Path(__file__).parent / "ai_recruiter.log"
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(),
    ],
)
logger = logging.getLogger("ai_recruiter")

# ---------------------------------------------------------------------------
# Lua Parser (reused from discord_webhook.py pattern)
# ---------------------------------------------------------------------------
class LuaParser:
    """Parse Lua SavedVariables files into Python dicts."""

    @staticmethod
    def parse_value(content: str, pos: int) -> tuple:
        while pos < len(content):
            if content[pos].isspace():
                pos += 1
            elif content[pos : pos + 2] == "--":
                while pos < len(content) and content[pos] != "\n":
                    pos += 1
            else:
                break
        if pos >= len(content):
            return None, pos

        if content[pos] in ('"', "'"):
            quote = content[pos]
            pos += 1
            value = []
            while pos < len(content) and content[pos] != quote:
                if content[pos] == "\\" and pos + 1 < len(content):
                    nc = content[pos + 1]
                    if nc == "n":
                        value.append("\n")
                    elif nc == "t":
                        value.append("\t")
                    elif nc == "\\":
                        value.append("\\")
                    elif nc == quote:
                        value.append(quote)
                    else:
                        value.append(nc)
                    pos += 2
                else:
                    value.append(content[pos])
                    pos += 1
            return "".join(value), pos + 1

        if content[pos].isdigit() or content[pos] == "-":
            m = re.match(r"-?\d+(?:\.\d+)?", content[pos:])
            if m:
                ns = m.group()
                val = float(ns) if "." in ns else int(ns)
                return val, pos + len(ns)

        if content[pos : pos + 4] == "true":
            return True, pos + 4
        if content[pos : pos + 5] == "false":
            return False, pos + 5
        if content[pos : pos + 3] == "nil":
            return None, pos + 3
        if content[pos] == "{":
            return LuaParser.parse_table(content, pos)
        return None, pos + 1

    @staticmethod
    def parse_table(content: str, pos: int) -> tuple:
        if content[pos] != "{":
            return None, pos
        pos += 1
        table = {}
        array = []
        is_array = True

        while pos < len(content):
            while pos < len(content):
                if content[pos].isspace():
                    pos += 1
                elif content[pos : pos + 2] == "--":
                    while pos < len(content) and content[pos] != "\n":
                        pos += 1
                else:
                    break
            if pos >= len(content):
                break
            if content[pos] == "}":
                pos += 1
                break

            if content[pos] == "[":
                pos += 1
                key, pos = LuaParser.parse_value(content, pos)
                while pos < len(content) and content[pos] != "=":
                    pos += 1
                pos += 1
                value, pos = LuaParser.parse_value(content, pos)
                table[key] = value
                is_array = False
            elif re.match(r"[a-zA-Z_][a-zA-Z0-9_]*\s*=", content[pos:]):
                m = re.match(r"([a-zA-Z_][a-zA-Z0-9_]*)\s*=", content[pos:])
                key = m.group(1)
                pos += m.end()
                value, pos = LuaParser.parse_value(content, pos)
                table[key] = value
                is_array = False
            else:
                value, pos = LuaParser.parse_value(content, pos)
                if value is not None:
                    array.append(value)

            while pos < len(content) and content[pos] in (",", ";", "\n", " ", "\t"):
                pos += 1

        return (array if is_array and not table else table), pos

    @staticmethod
    def parse_savedvariables(content: str) -> Dict[str, Any]:
        result = {}
        for m in re.finditer(r"([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*\{", content):
            var_name = m.group(1)
            pos = m.start() + len(m.group(0)) - 1
            try:
                value, _ = LuaParser.parse_table(content, pos)
                result[var_name] = value
            except Exception as e:
                logger.warning(f"Failed to parse {var_name}: {e}")
        return result

    @staticmethod
    def extract_section(content: str, key_name: str) -> Optional[Any]:
        pattern = re.compile(rf'\["{re.escape(key_name)}"\]\s*=\s*\{{')
        m = pattern.search(content)
        if not m:
            return None
        brace_start = m.end() - 1
        try:
            result, _ = LuaParser.parse_table(content, brace_start)
            return result
        except Exception:
            return None

# ---------------------------------------------------------------------------
# Lua Writer
# ---------------------------------------------------------------------------
class LuaWriter:
    """Serialize Python dicts/lists to Lua SavedVariables format."""

    @staticmethod
    def escape_string(s: str) -> str:
        return (
            s.replace("\\", "\\\\")
            .replace('"', '\\"')
            .replace("\n", "\\n")
            .replace("\t", "\\t")
        )

    @staticmethod
    def to_lua(value, indent: int = 1) -> str:
        pad = "\t" * indent
        pad_inner = "\t" * (indent + 1)

        if value is None:
            return "nil"
        if isinstance(value, bool):
            return "true" if value else "false"
        if isinstance(value, int):
            return str(value)
        if isinstance(value, float):
            return f"{value:.6f}".rstrip("0").rstrip(".")
        if isinstance(value, str):
            return f'"{LuaWriter.escape_string(value)}"'
        if isinstance(value, list):
            if not value:
                return "{}"
            items = []
            for v in value:
                items.append(f"{pad_inner}{LuaWriter.to_lua(v, indent + 1)},")
            return "{\n" + "\n".join(items) + f"\n{pad}}}"
        if isinstance(value, dict):
            if not value:
                return "{}"
            items = []
            for k, v in value.items():
                lua_key = (
                    f'["{LuaWriter.escape_string(str(k))}"]'
                    if not re.match(r"^[a-zA-Z_][a-zA-Z0-9_]*$", str(k))
                    else str(k)
                )
                items.append(f"{pad_inner}{lua_key} = {LuaWriter.to_lua(v, indent + 1)},")
            return "{\n" + "\n".join(items) + f"\n{pad}}}"
        return "nil"

    @staticmethod
    def write_savedvariable(path: Path, var_name: str, data: dict):
        lines = [f"{var_name} = {{"]
        pad = "\t"
        for k, v in data.items():
            lua_key = (
                f'["{LuaWriter.escape_string(str(k))}"]'
                if not re.match(r"^[a-zA-Z_][a-zA-Z0-9_]*$", str(k))
                else str(k)
            )
            lines.append(f"{pad}{lua_key} = {LuaWriter.to_lua(v, 1)},")
        lines.append("}")
        lines.append("")

        path.write_text("\n".join(lines), encoding="utf-8")
        logger.info(f"Wrote {path} ({len(data)} keys)")

# ---------------------------------------------------------------------------
# AI Recruiter Engine
# ---------------------------------------------------------------------------
class AIRecruiter:
    """Main engine: reads WoW data, generates AI content, writes output."""

    # System prompts
    MSG_SYSTEM = (
        "Tu es un recruteur de guilde World of Warcraft. "
        "Tu generes des messages de recrutement personnalises et naturels. "
        "Informations de la guilde:\n{guild_info}\n\n"
        "Pour chaque joueur, adapte ton message a sa classe, son niveau, sa zone. "
        "Sois amical, pas spammy. Max 240 caracteres. En {language}. "
        "Ne mets pas de guillemets autour du message. Reponds UNIQUEMENT avec le message."
    )

    RESP_SYSTEM = (
        "Tu es un recruteur de guilde WoW en conversation. "
        "Informations de la guilde:\n{guild_info}\n\n"
        "Historique de la conversation:\n{context}\n\n"
        "Le joueur vient de repondre: \"{reply}\"\n\n"
        "Genere une reponse naturelle et amicale. "
        "Si le joueur est interesse -> propose l'invite de guilde. "
        "Si c'est une question -> reponds avec les infos de la guilde. "
        "Si negatif -> remercie poliment et souhaite bonne continuation. "
        "Max 240 caracteres. En {language}. "
        "Ne mets pas de guillemets. Reponds UNIQUEMENT avec le message."
    )

    TARGET_SYSTEM = (
        "Tu es un analyste de recrutement pour une guilde WoW. "
        "Voici l'historique de recrutement:\n{stats}\n\n"
        "Analyse quels facteurs predisent le mieux qu'un joueur rejoindra la guilde. "
        "Retourne un JSON avec des poids (0.0-3.0) pour chaque facteur:\n"
        '{{ "noGuild": float, "levelHigh": float, "sameRealm": float, '
        '"classHealer": float, "classTank": float, "recentlySeen": float, '
        '"hasOptedIn": float }}\n'
        "Reponds UNIQUEMENT avec le JSON, sans markdown ni explication."
    )

    HEALER_CLASSES = {"PRIEST", "DRUID", "SHAMAN", "MONK", "PALADIN", "EVOKER"}
    TANK_CLASSES = {"WARRIOR", "PALADIN", "DEATHKNIGHT", "DRUID", "MONK", "DEMONHUNTER"}

    def __init__(self, config: dict):
        self.config = config
        self.client = anthropic.Anthropic(api_key=config["anthropic_api_key"])
        self.model = config.get("ai_model", "claude-sonnet-4-5-20250929")
        self.language = config.get("ai_language", "fr")
        self.max_msg_len = config.get("max_message_length", 240)

        self.guild_info = self._build_guild_info()
        self.sv_path = Path(config["savedvariables_path"])
        self.last_processed = 0.0

    def _build_guild_info(self) -> str:
        parts = []
        if self.config.get("guild_name"):
            parts.append(f"Nom: {self.config['guild_name']}")
        if self.config.get("guild_description"):
            parts.append(f"Description: {self.config['guild_description']}")
        if self.config.get("guild_discord"):
            parts.append(f"Discord: {self.config['guild_discord']}")
        return "\n".join(parts) if parts else "Guilde de recrutement WoW"

    def read_db(self) -> Optional[Dict]:
        """Read and parse the addon SavedVariables."""
        if not self.sv_path.exists():
            logger.warning(f"SavedVariables not found: {self.sv_path}")
            return None

        try:
            content = self.sv_path.read_text(encoding="utf-8")
            data = LuaParser.parse_savedvariables(content)
            return data.get("CelestialRecruiterDB")
        except Exception as e:
            logger.error(f"Failed to read DB: {e}")
            return None

    def read_existing_ai(self) -> Dict:
        """Read existing CelestialRecruiterAI from the same SavedVariables file."""
        if not self.sv_path.exists():
            return {}
        try:
            content = self.sv_path.read_text(encoding="utf-8")
            data = LuaParser.parse_savedvariables(content)
            return data.get("CelestialRecruiterAI", {})
        except Exception:
            return {}

    # -----------------------------------------------------------------------
    # Write AI data into the existing SavedVariables file
    # -----------------------------------------------------------------------
    def _remove_variable_block(self, content: str, var_name: str) -> str:
        """Remove a top-level variable assignment block from Lua content."""
        pattern = re.compile(rf'^{re.escape(var_name)}\s*=\s*\{{', re.MULTILINE)
        match = pattern.search(content)
        if not match:
            return content

        # Find matching closing brace using brace counting
        start = match.start()
        brace_pos = match.end() - 1  # position of opening {
        depth = 1
        pos = brace_pos + 1
        in_string = False
        string_char = None

        while pos < len(content) and depth > 0:
            ch = content[pos]
            if in_string:
                if ch == '\\':
                    pos += 2
                    continue
                if ch == string_char:
                    in_string = False
            else:
                if ch in ('"', "'"):
                    in_string = True
                    string_char = ch
                elif ch == '{':
                    depth += 1
                elif ch == '}':
                    depth -= 1
            pos += 1

        # Remove from start to pos (inclusive of trailing newlines)
        end = pos
        while end < len(content) and content[end] in ('\n', '\r', ' ', '\t'):
            end += 1

        return content[:start] + content[end:]

    def write_ai_to_sv(self, data: dict):
        """Write CelestialRecruiterAI into the existing SavedVariables file.

        WoW stores ALL addon SavedVariables in a single file named after the
        addon folder (CelestialRecruiter.lua). We must inject our AI variable
        into that same file, NOT write a separate file.
        """
        # Read existing content
        existing = ""
        if self.sv_path.exists():
            existing = self.sv_path.read_text(encoding="utf-8")

        # Remove old CelestialRecruiterAI block if present
        existing = self._remove_variable_block(existing, "CelestialRecruiterAI")

        # Generate new AI block
        lines = ["CelestialRecruiterAI = {"]
        pad = "\t"
        for k, v in data.items():
            lua_key = (
                f'["{LuaWriter.escape_string(str(k))}"]'
                if not re.match(r"^[a-zA-Z_][a-zA-Z0-9_]*$", str(k))
                else str(k)
            )
            lines.append(f"{pad}{lua_key} = {LuaWriter.to_lua(v, 1)},")
        lines.append("}")
        lines.append("")
        ai_block = "\n".join(lines)

        # Append to existing content
        final = existing.rstrip() + "\n\n" + ai_block

        self.sv_path.write_text(final, encoding="utf-8")
        logger.info(f"Wrote CelestialRecruiterAI into {self.sv_path} ({len(data)} keys)")

    def extract_contacts(self, db: Dict) -> Dict[str, Dict]:
        """Extract contacts from the DB structure."""
        # AceDB stores globals under a nested key
        # Structure: CelestialRecruiterDB -> global -> Default -> contacts
        global_data = db.get("global", {})

        # Try direct access first
        contacts = global_data.get("contacts")
        if contacts and isinstance(contacts, dict):
            return contacts

        # AceDB namespaced: global -> Default -> contacts
        for profile_name, profile_data in global_data.items():
            if isinstance(profile_data, dict) and "contacts" in profile_data:
                return profile_data["contacts"]

        return {}

    def extract_queue(self, db: Dict) -> List[str]:
        """Extract queue from the DB structure."""
        global_data = db.get("global", {})
        queue = global_data.get("queue")
        if queue and isinstance(queue, list):
            return queue

        for profile_name, profile_data in global_data.items():
            if isinstance(profile_data, dict) and "queue" in profile_data:
                q = profile_data["queue"]
                return q if isinstance(q, list) else []
        return []

    def extract_pending_replies(self, db: Dict) -> Dict[str, Dict]:
        """Extract pending AI reply requests."""
        global_data = db.get("global", {})
        pending = global_data.get("aiPendingReplies")
        if pending and isinstance(pending, dict):
            return pending

        for profile_name, profile_data in global_data.items():
            if isinstance(profile_data, dict) and "aiPendingReplies" in profile_data:
                return profile_data["aiPendingReplies"]
        return {}

    def extract_profile(self, db: Dict) -> Dict:
        """Extract profile settings."""
        profiles = db.get("profiles", {})
        for name, data in profiles.items():
            if isinstance(data, dict):
                return data
        return db.get("profile", {})

    # -----------------------------------------------------------------------
    # Message Generation
    # -----------------------------------------------------------------------
    def generate_messages(self, contacts: Dict, queue: List[str], existing_messages: Dict) -> Dict[str, str]:
        """Generate personalized recruitment messages for queued contacts."""
        messages = {}
        to_generate = []

        for key in queue:
            # Skip if we already have a message
            if key in existing_messages and existing_messages[key]:
                messages[key] = existing_messages[key]
                continue

            contact = contacts.get(key, {})
            # Skip already contacted/invited/joined/ignored
            status = contact.get("status", "new")
            if status in ("contacted", "invited", "joined", "ignored"):
                continue

            to_generate.append((key, contact))

        if not to_generate:
            logger.info("No new messages to generate")
            return messages

        # Batch: generate up to 20 messages at a time
        batch_size = 20
        for i in range(0, len(to_generate), batch_size):
            batch = to_generate[i : i + batch_size]
            batch_messages = self._generate_message_batch(batch)
            messages.update(batch_messages)

        logger.info(f"Generated {len(messages)} messages ({len(to_generate)} new)")
        return messages

    def _generate_message_batch(self, batch: List[tuple]) -> Dict[str, str]:
        """Generate messages for a batch of contacts in a single API call."""
        if not batch:
            return {}

        # Build player descriptions
        player_lines = []
        for key, contact in batch:
            parts = [f"- {key}"]
            if contact.get("level"):
                parts.append(f"lvl {contact['level']}")
            if contact.get("classLabel") or contact.get("classFile"):
                parts.append(contact.get("classLabel") or contact.get("classFile"))
            if contact.get("zone"):
                parts.append(f"zone: {contact['zone']}")
            if contact.get("guild"):
                parts.append(f"guilde: {contact['guild']}")
            else:
                parts.append("sans guilde")
            if contact.get("race"):
                parts.append(contact["race"])
            player_lines.append(" | ".join(parts))

        user_prompt = (
            f"Genere un message de recrutement personnalise pour chacun de ces {len(batch)} joueurs.\n"
            f"Format: une ligne par joueur, exactement: NomJoueur-Serveur|||message\n"
            f"Le message doit faire max {self.max_msg_len} caracteres.\n\n"
            + "\n".join(player_lines)
        )

        system = self.MSG_SYSTEM.format(
            guild_info=self.guild_info, language=self.language
        )

        try:
            response = self.client.messages.create(
                model=self.model,
                max_tokens=4096,
                system=system,
                messages=[{"role": "user", "content": user_prompt}],
            )

            text = response.content[0].text.strip()
            return self._parse_batch_response(text, batch)

        except anthropic.AuthenticationError as e:
            logger.error(f"Claude API auth error: {e}")
            logger.error("Verifiez votre cle API dans config.json (anthropic_api_key)")
            return {}
        except anthropic.RateLimitError as e:
            logger.warning(f"Claude API rate limit: {e}")
            logger.warning("Credits insuffisants ou trop de requetes. Voir https://console.anthropic.com/")
            return {}
        except Exception as e:
            logger.error(f"Claude API error (messages): {e}")
            return {}

    def _parse_batch_response(self, text: str, batch: List[tuple]) -> Dict[str, str]:
        """Parse Claude's batch response: PlayerName-Realm|||message"""
        messages = {}
        lines = text.strip().split("\n")

        for line in lines:
            line = line.strip()
            if "|||" not in line:
                continue
            parts = line.split("|||", 1)
            if len(parts) != 2:
                continue
            key = parts[0].strip()
            msg = parts[1].strip()

            # Truncate to max length
            if len(msg) > self.max_msg_len:
                msg = msg[: self.max_msg_len - 3] + "..."

            # Validate key exists in batch
            batch_keys = {k for k, _ in batch}
            if key in batch_keys:
                messages[key] = msg
            else:
                # Try fuzzy match (Claude might slightly alter the name)
                for bk, _ in batch:
                    if bk.lower() == key.lower():
                        messages[bk] = msg
                        break

        return messages

    # -----------------------------------------------------------------------
    # Conversation Responses
    # -----------------------------------------------------------------------
    def generate_responses(self, pending: Dict[str, Dict]) -> Dict[str, str]:
        """Generate AI responses for pending conversation replies."""
        if not pending:
            return {}

        responses = {}
        for key, data in pending.items():
            msg = data.get("msg", "")
            context = data.get("context", "")
            if not msg:
                continue

            response = self._generate_single_response(key, msg, context)
            if response:
                responses[key] = response

        logger.info(f"Generated {len(responses)} conversation responses")
        return responses

    def _generate_single_response(self, key: str, reply: str, context: str) -> Optional[str]:
        """Generate a single conversation response."""
        system = self.RESP_SYSTEM.format(
            guild_info=self.guild_info,
            context=context or "(pas d'historique)",
            reply=reply,
            language=self.language,
        )

        try:
            response = self.client.messages.create(
                model=self.model,
                max_tokens=300,
                system=system,
                messages=[{"role": "user", "content": f"Genere la reponse pour {key}"}],
            )

            text = response.content[0].text.strip()
            # Strip any quotes Claude might add
            text = text.strip('"').strip("'")
            if len(text) > self.max_msg_len:
                text = text[: self.max_msg_len - 3] + "..."
            return text

        except Exception as e:
            logger.error(f"Claude API error (response for {key}): {e}")
            return None

    # -----------------------------------------------------------------------
    # Targeting Analysis
    # -----------------------------------------------------------------------
    def analyze_targeting(self, contacts: Dict) -> Dict:
        """Analyze recruitment history to generate targeting weights."""
        # Build stats summary
        joined = []
        ignored = []
        total = 0

        for key, c in contacts.items():
            if not isinstance(c, dict):
                continue
            total += 1
            status = c.get("status", "new")
            if status == "joined":
                joined.append(c)
            elif status == "ignored":
                ignored.append(c)

        if total < 10:
            # Not enough data for meaningful analysis
            return self._default_weights()

        stats_text = (
            f"Total contacts: {total}\n"
            f"Recrues (joined): {len(joined)}\n"
            f"Ignores: {len(ignored)}\n"
            f"Taux de conversion: {len(joined)/max(1,total)*100:.1f}%\n"
        )

        # Add class distribution of joined
        if joined:
            class_counts = {}
            for c in joined:
                cls = c.get("classFile", "UNKNOWN")
                class_counts[cls] = class_counts.get(cls, 0) + 1
            stats_text += "Classes des recrues: " + ", ".join(
                f"{k}={v}" for k, v in sorted(class_counts.items(), key=lambda x: -x[1])
            ) + "\n"

            # Guild status
            no_guild = sum(1 for c in joined if not c.get("guild"))
            stats_text += f"Sans guilde parmi recrues: {no_guild}/{len(joined)}\n"

        system = self.TARGET_SYSTEM.format(stats=stats_text)

        try:
            response = self.client.messages.create(
                model=self.model,
                max_tokens=500,
                system=system,
                messages=[{"role": "user", "content": "Analyse et retourne les poids JSON."}],
            )

            text = response.content[0].text.strip()
            # Extract JSON from response
            json_match = re.search(r"\{[^}]+\}", text)
            if json_match:
                weights = json.loads(json_match.group())
                return {"weights": weights}

        except Exception as e:
            logger.error(f"Claude API error (targeting): {e}")

        return self._default_weights()

    def _default_weights(self) -> Dict:
        return {
            "weights": {
                "noGuild": 2.0,
                "levelHigh": 1.5,
                "sameRealm": 1.2,
                "classHealer": 1.2,
                "classTank": 1.1,
                "recentlySeen": 1.3,
                "hasOptedIn": 2.5,
            }
        }

    def compute_priority_list(self, contacts: Dict, queue: List[str], weights: Dict) -> List[str]:
        """Score and sort queue contacts by targeting weights."""
        w = weights.get("weights", self._default_weights()["weights"])
        scored = []

        player_realm = self.config.get("player_realm", "")

        for key in queue:
            c = contacts.get(key, {})
            if not isinstance(c, dict):
                continue

            score = 1.0

            # No guild bonus
            if not c.get("guild"):
                score *= w.get("noGuild", 2.0)

            # Level bonus (higher = better)
            level = c.get("level", 0)
            if isinstance(level, (int, float)) and level >= 70:
                score *= w.get("levelHigh", 1.5)

            # Same realm
            if player_realm and key.endswith(f"-{player_realm}"):
                score *= w.get("sameRealm", 1.2)

            # Class bonuses
            class_file = (c.get("classFile") or "").upper()
            if class_file in self.HEALER_CLASSES:
                score *= w.get("classHealer", 1.2)
            if class_file in self.TANK_CLASSES:
                score *= w.get("classTank", 1.1)

            # Recently seen bonus
            last_seen = c.get("lastSeen", 0)
            if isinstance(last_seen, (int, float)) and last_seen > 0:
                age_hours = (time.time() - last_seen) / 3600
                if age_hours < 24:
                    score *= w.get("recentlySeen", 1.3)

            # Opt-in bonus
            if c.get("optedIn"):
                score *= w.get("hasOptedIn", 2.5)

            scored.append((key, score))

        # Sort by score descending
        scored.sort(key=lambda x: -x[1])
        return [k for k, _ in scored]

    # -----------------------------------------------------------------------
    # Main Processing
    # -----------------------------------------------------------------------
    def process(self) -> bool:
        """Run one processing cycle. Returns True if any content was generated."""
        logger.info("=" * 60)
        logger.info("Processing cycle started")

        db = self.read_db()
        if not db:
            logger.warning("No DB data available")
            return False

        contacts = self.extract_contacts(db)
        queue = self.extract_queue(db)
        pending_replies = self.extract_pending_replies(db)
        existing_ai = self.read_existing_ai()

        logger.info(
            f"Found {len(contacts)} contacts, {len(queue)} in queue, "
            f"{len(pending_replies)} pending replies"
        )

        if not queue and not pending_replies:
            logger.info("Nothing to process")
            return False

        # 1. Generate recruitment messages
        existing_messages = existing_ai.get("messages", {})
        if not isinstance(existing_messages, dict):
            existing_messages = {}
        messages = self.generate_messages(contacts, queue, existing_messages)

        # 2. Generate conversation responses
        responses = self.generate_responses(pending_replies)

        # 3. Analyze targeting (do this less frequently - only if enough data)
        targeting = existing_ai.get("targeting", self._default_weights())
        if len(contacts) >= 20:
            try:
                targeting = self.analyze_targeting(contacts)
            except Exception as e:
                logger.warning(f"Targeting analysis failed: {e}")

        # 4. Compute priority list
        weights = targeting if isinstance(targeting, dict) else self._default_weights()
        priority = self.compute_priority_list(contacts, queue, weights)

        # 5. Write output
        output = {
            "version": 1,
            "generatedAt": int(time.time()),
            "messages": messages,
            "responses": responses,
            "targeting": {
                "weights": weights.get("weights", {}),
                "priority": priority,
            },
            "pendingReplies": {},
        }

        self.write_ai_to_sv(output)
        self.last_processed = time.time()

        logger.info(
            f"Cycle complete: {len(messages)} messages, {len(responses)} responses, "
            f"{len(priority)} priority entries"
        )
        return True


# ---------------------------------------------------------------------------
# File Watcher
# ---------------------------------------------------------------------------
class SVFileHandler(FileSystemEventHandler):
    """Watch SavedVariables for changes and trigger processing."""

    def __init__(self, engine: AIRecruiter, cooldown: int = 30):
        self.engine = engine
        self.cooldown = cooldown
        self.last_trigger = 0.0

    def on_modified(self, event):
        if event.is_directory:
            return
        path = Path(event.src_path)
        if path.name != self.engine.sv_path.name:
            return

        now = time.time()
        if now - self.last_trigger < self.cooldown:
            return

        self.last_trigger = now
        logger.info(f"SavedVariables changed: {path.name}")
        try:
            # Small delay to let WoW finish writing
            time.sleep(2)
            self.engine.process()
        except Exception as e:
            logger.error(f"Processing error: {e}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def load_config(config_path: str) -> dict:
    """Load configuration from JSON file."""
    path = Path(config_path)
    if not path.exists():
        logger.error(f"Config file not found: {path}")
        logger.info("Create config.json with:")
        logger.info(json.dumps({
            "savedvariables_path": "C:\\Path\\To\\WoW\\_retail_\\WTF\\Account\\ACCOUNT\\SavedVariables\\CelestialRecruiter.lua",
            "anthropic_api_key": "sk-ant-...",
            "ai_model": "claude-sonnet-4-5-20250929",
            "guild_name": "MaGuilde",
            "guild_description": "Guilde PvE semi-HL, ambiance chill",
            "guild_discord": "https://discord.gg/...",
            "ai_language": "fr",
            "max_message_length": 240,
            "watch_interval": 30,
        }, indent=2))
        sys.exit(1)

    with open(path, "r", encoding="utf-8") as f:
        config = json.load(f)

    # Validate required keys
    required = ["savedvariables_path", "anthropic_api_key"]
    for key in required:
        if not config.get(key):
            logger.error(f"Missing required config key: {key}")
            sys.exit(1)

    return config


def main():
    parser = argparse.ArgumentParser(description="CelestialRecruiter AI Companion")
    parser.add_argument("--config", default="config.json", help="Path to config.json")
    parser.add_argument("--once", action="store_true", help="Run once and exit (no watch loop)")
    args = parser.parse_args()

    config = load_config(args.config)
    engine = AIRecruiter(config)

    logger.info("CelestialRecruiter AI Companion started")
    logger.info(f"Model: {engine.model}")
    logger.info(f"Guild: {config.get('guild_name', '?')}")
    logger.info(f"SavedVariables: {engine.sv_path}")
    logger.info(f"AI output: injected into same file")

    if args.once:
        engine.process()
        return

    # Initial processing
    engine.process()

    # Watch loop - try watchdog first, fall back to polling
    use_watchdog = False
    if WATCHDOG_AVAILABLE:
        try:
            logger.info("Starting file watcher (watchdog)...")
            handler = SVFileHandler(engine, cooldown=config.get("watch_interval", 30))
            observer = Observer()
            observer.schedule(handler, str(engine.sv_path.parent), recursive=False)
            observer.start()
            use_watchdog = True
        except Exception as e:
            logger.warning(f"Watchdog failed (Python 3.13+ compat issue?): {e}")
            logger.info("Falling back to polling mode...")
            use_watchdog = False

    if use_watchdog:
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            logger.info("Shutting down...")
            observer.stop()
        observer.join()
    else:
        # Fallback: polling
        interval = config.get("watch_interval", 30)
        logger.info(f"Starting polling loop (every {interval}s)...")
        last_mtime = 0.0

        try:
            while True:
                time.sleep(interval)
                try:
                    mtime = engine.sv_path.stat().st_mtime
                    if mtime > last_mtime:
                        last_mtime = mtime
                        time.sleep(2)  # Let WoW finish writing
                        engine.process()
                except FileNotFoundError:
                    pass
                except Exception as e:
                    logger.error(f"Polling error: {e}")
        except KeyboardInterrupt:
            logger.info("Shutting down...")


if __name__ == "__main__":
    main()
