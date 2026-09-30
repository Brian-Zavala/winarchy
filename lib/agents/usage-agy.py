# winarchy agent usage collector for Antigravity CLI (agy).
# Run by lib/agents.ps1 (Update-AgentUsage), which reads the record it prints.
"""Collect Antigravity CLI usage into one display-ready JSON record.

Everything the agents panel shows for Antigravity comes from this command:
local prompt history and configuration from ~/.gemini/antigravity-cli.
The panel itself only ever reads the JSON this prints; it never talks to
disk formats or endpoints directly.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import shutil
import sys
from pathlib import Path
from typing import Any

AGENT_ID = "agy"
AGENT_NAME = "Antigravity"
AUTH_HELP = "Run `agy` to start a session."


def config_dir() -> Path:
  override = os.environ.get("ANTIGRAVITY_CONFIG_DIR") or os.environ.get("GEMINI_CONFIG_DIR")
  if override:
    return Path(os.path.expandvars(os.path.expanduser(override))).resolve()
  return Path.home() / ".gemini" / "antigravity-cli"


def is_installed() -> bool:
  if shutil.which("agy") or shutil.which("antigravity"):
    return True
  local_app_data = os.environ.get("LOCALAPPDATA")
  if local_app_data:
    p1 = Path(local_app_data) / "agy" / "bin" / "agy.exe"
    p2 = Path(local_app_data) / "Programs" / "Antigravity" / "bin" / "antigravity.cmd"
    if p1.is_file() or p2.is_file():
      return True
  app_data = os.environ.get("APPDATA")
  if app_data and (Path(app_data) / "npm" / "agy.cmd").is_file():
    return True
  if config_dir().is_dir():
    return True
  return False


def date_string(value: dt.date) -> str:
  return value.strftime("%Y-%m-%d")


def recent_date_strings() -> list[str]:
  today = dt.datetime.now().date()
  return [date_string(today - dt.timedelta(days=offset)) for offset in range(6, -1, -1)]


def local_date_from_millis(ms: Any) -> str:
  try:
    sec = float(ms) / 1000.0
    return date_string(dt.datetime.fromtimestamp(sec).date())
  except Exception:
    return date_string(dt.datetime.now().date())


def collect_usage() -> dict[str, Any]:
  installed = is_installed()
  c_dir = config_dir()
  history_file = c_dir / "history.jsonl"
  settings_file = c_dir / "settings.json"

  recent_dates = recent_date_strings()
  day_counts: dict[str, int] = {d: 0 for d in recent_dates}
  active_dates: set[str] = set()
  conversation_ids: set[str] = set()
  today_str = recent_dates[-1]

  today_prompts = 0
  total_prompts = 0
  total_chars = 0
  today_chars = 0

  if history_file.is_file():
    try:
      with open(history_file, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
          line = line.strip()
          if not line:
            continue
          try:
            item = json.loads(line)
          except Exception:
            continue
          total_prompts += 1
          display_text = str(item.get("display") or "")
          char_len = len(display_text)
          total_chars += char_len

          cid = item.get("conversationId")
          if cid:
            conversation_ids.add(cid)
          ts = item.get("timestamp")
          if ts:
            d_str = local_date_from_millis(ts)
            active_dates.add(d_str)
            if d_str in day_counts:
              day_counts[d_str] += 1
            if d_str == today_str:
              today_prompts += 1
              today_chars += char_len
    except Exception:
      pass

  # If brain/ directory has conversation folders, include them in session counting
  brain_dir = c_dir / "brain"
  if brain_dir.is_dir():
    try:
      for entry in brain_dir.iterdir():
        if entry.is_dir() and not entry.name.startswith("."):
          conversation_ids.add(entry.name)
    except Exception:
      pass

  # Check active model from settings.json
  tier_label = ""
  if settings_file.is_file():
    try:
      with open(settings_file, "r", encoding="utf-8", errors="replace") as f:
        settings = json.load(f)
      model_raw = str(settings.get("model", "")).strip()
      if model_raw:
        # e.g. "Gemini 3.8 Flash (High)" -> "Gemini 3.8 Flash"
        tier_label = model_raw.split(" (")[0]
    except Exception:
      pass

  recent_days = [{"date": d, "messageCount": day_counts[d]} for d in recent_dates]
  total_sessions = len(conversation_ids)
  today_sessions = 1 if today_prompts > 0 else 0

  now_utc = dt.datetime.now(dt.timezone.utc).isoformat()

  # Estimate tokens based on prompt length if not reported by an endpoint
  today_tokens = max(0, round(today_chars / 4.0)) if today_chars else 0
  total_tokens = max(0, round(total_chars / 4.0)) if total_chars else 0

  model_usage: dict[str, Any] = {}
  if tier_label:
    model_usage[tier_label] = {
      "inputTokens": total_tokens,
      "outputTokens": 0,
      "cacheReadInputTokens": 0,
      "cacheCreationInputTokens": 0,
    }

  today_tokens_by_model: dict[str, int] = {}
  if tier_label and today_tokens:
    today_tokens_by_model[tier_label] = today_tokens

  if not installed and total_prompts == 0:
    return {
      "schemaVersion": 1,
      "id": AGENT_ID,
      "name": AGENT_NAME,
      "updatedAt": now_utc,
      "ready": False,
      "hasLocalStats": False,
      "todayPrompts": 0,
      "todaySessions": 0,
      "todayTotalTokens": 0,
      "todayTokensByModel": {},
      "recentDays": recent_days,
      "totalPrompts": 0,
      "totalSessions": 0,
      "activeDays": 0,
      "activeDates": [],
      "modelUsage": {},
      "limits": [],
      "tierLabel": "",
      "usageStatusText": "Antigravity unavailable",
      "authHelpText": "winget install -e --id Google.AntigravityCLI",
    }

  return {
    "schemaVersion": 1,
    "id": AGENT_ID,
    "name": AGENT_NAME,
    "updatedAt": now_utc,
    "ready": True,
    "hasLocalStats": True,
    "todayPrompts": today_prompts,
    "todaySessions": today_sessions,
    "todayTotalTokens": today_tokens,
    "todayTokensByModel": today_tokens_by_model,
    "recentDays": recent_days,
    "totalPrompts": total_prompts,
    "totalSessions": total_sessions,
    "activeDays": len(active_dates),
    "activeDates": sorted(list(active_dates)),
    "modelUsage": model_usage,
    "limits": [],
    "tierLabel": tier_label,
    "usageStatusText": "",
    "authHelpText": "",
  }


def main() -> None:
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--force", action="store_true", help="force refresh")
  parser.add_argument("--limits-only", action="store_true", help="probe limits only")
  parser.parse_args()

  record = collect_usage()
  json.dump(record, sys.stdout, indent=2)
  sys.stdout.write("\n")


if __name__ == "__main__":
  main()
