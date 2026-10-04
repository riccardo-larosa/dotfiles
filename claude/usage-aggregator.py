#!/usr/bin/env python3
"""Aggregate Claude Code token usage and cost from local transcripts.

Scans ~/.claude/projects/*/*.jsonl for assistant messages with usage data,
buckets by today / this-week / this-month (UTC), and prints a single
ANSI-colored line for the status bar.

Pricing is approximate — adjust PRICING below if Anthropic rates change.
"""
import glob
import json
import os
from datetime import datetime, timedelta, timezone

now = datetime.now(timezone.utc)
today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
week_start = today_start - timedelta(days=today_start.weekday())  # Monday
month_start = today_start.replace(day=1)
month_ts = month_start.timestamp()

# (input, output, cache_creation, cache_read) USD per 1M tokens
PRICING = {
    "opus":   (15.0, 75.0, 18.75, 1.50),
    "sonnet": (3.0, 15.0, 3.75, 0.30),
    "haiku":  (1.0, 5.0, 1.25, 0.10),
}


def price_for(model: str):
    if not model:
        return PRICING["sonnet"]
    m = model.lower()
    if "opus" in m:
        return PRICING["opus"]
    if "haiku" in m:
        return PRICING["haiku"]
    return PRICING["sonnet"]


buckets = {k: [0, 0.0] for k in ("today", "week", "month")}  # [tokens, cost_usd]

home = os.path.expanduser("~")
for fp in glob.iglob(f"{home}/.claude/projects/*/*.jsonl"):
    try:
        if os.stat(fp).st_mtime < month_ts:
            continue
    except OSError:
        continue
    try:
        with open(fp, "rb") as f:
            for raw in f:
                if b'"usage"' not in raw or b'"assistant"' not in raw:
                    continue
                try:
                    d = json.loads(raw)
                except Exception:
                    continue
                if d.get("type") != "assistant":
                    continue
                msg = d.get("message") or {}
                u = msg.get("usage")
                ts_str = d.get("timestamp")
                if not u or not ts_str:
                    continue
                try:
                    ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
                except Exception:
                    continue
                if ts < month_start:
                    continue

                inp = u.get("input_tokens") or 0
                out = u.get("output_tokens") or 0
                cc = u.get("cache_creation_input_tokens") or 0
                cr = u.get("cache_read_input_tokens") or 0
                pi, po, pcc, pcr = price_for(msg.get("model"))
                tokens = inp + out + cc + cr
                cost = (inp * pi + out * po + cc * pcc + cr * pcr) / 1_000_000

                for key, start in (("month", month_start), ("week", week_start), ("today", today_start)):
                    if ts >= start:
                        buckets[key][0] += tokens
                        buckets[key][1] += cost
    except OSError:
        continue


def fmt_tokens(n: int) -> str:
    if n >= 1_000_000_000:
        return f"{n/1e9:.2f}B"
    if n >= 1_000_000:
        return f"{n/1e6:.1f}M"
    if n >= 1_000:
        return f"{n/1e3:.1f}K"
    return str(n)


DIM = "\033[2m"
WHITE = "\033[97m"
ORANGE = "\033[38;2;255;122;61m"
RESET = "\033[0m"

parts = []
for label, key in (("Today", "today"), ("Week", "week"), ("Month", "month")):
    t, c = buckets[key]
    parts.append(f"{WHITE}{label} {fmt_tokens(t)} {ORANGE}${c:.2f}{RESET}")
print(f"{DIM}Usage {RESET}" + f"{DIM} · {RESET}".join(parts))
