"""A stand-in for `codex app-server`: newline-delimited JSON-RPC on stdin/stdout.

It deliberately makes the client's life hard in the ways a real server can:
notifications without an id interleaved with replies, a reply that arrives late
(to exercise the timeout loop), and output flushed line by line.

FAKE_CODEX_ACCOUNT_HANGS: account/read never answers, as Codex 0.158's can.
FAKE_CODEX_NO_PLAN: the rate limits leave planType out, so account/read names it.
"""
import json
import os
import sys
import time


def send(obj):
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


for raw in sys.stdin:
    try:
        msg = json.loads(raw)
    except Exception:
        continue
    mid = msg.get("id")
    method = msg.get("method")
    if method == "initialize":
        send({"method": "log", "params": {"text": "noise before the reply"}})
        send({"id": mid, "result": {"serverInfo": {"name": "fake-codex"}}})
    elif method == "initialized":
        continue  # a notification: no reply
    elif method == "account/read":
        if os.environ.get("FAKE_CODEX_ACCOUNT_HANGS"):
            continue
        send({"method": "account/updated", "params": {}})
        send({"id": mid, "result": {"account": {"type": "chatgpt", "planType": "plus"}}})
    elif method == "account/rateLimits/read":
        time.sleep(0.6)  # late, but inside the deadline
        limits = {
            "planType": "pro",
            "primary": {"usedPercent": 42, "windowDurationMins": 300, "resetsAt": 1790000000},
            "secondary": {"usedPercent": 7.5, "windowDurationMins": 10080, "resetsAt": 1790500000},
        }
        if os.environ.get("FAKE_CODEX_NO_PLAN"):
            del limits["planType"]
        send({"id": mid, "result": {"rateLimits": limits}})
