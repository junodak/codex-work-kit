#!/usr/bin/env python3
"""codex exec --json 이벤트 파일에서 에이전트의 마지막 답을 꺼낸다.

사용: python3 kit/scripts/lastmsg.py <파일.jsonl>
버전에 따라 type/item_type, agent_message/assistant_message 로 달라서 둘 다 처리한다.
못 찾으면 종료 코드 1. 원본 jsonl이 정본이다.
"""
import json
import sys


def texts(o):
    if isinstance(o, dict):
        kind = " ".join(str(o.get(k, "")) for k in ("type", "item_type", "kind", "role"))
        if ("message" in kind or "assistant" in kind) and "user" not in kind and isinstance(o.get("text"), str):
            yield o["text"]
        for v in o.values():
            yield from texts(v)
    elif isinstance(o, list):
        for v in o:
            yield from texts(v)


def last_message(path):
    last = ""
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            try:
                for t in texts(json.loads(line)):
                    last = t
            except json.JSONDecodeError:
                pass
    return last


if __name__ == "__main__":
    msg = last_message(sys.argv[1])
    print(msg or "(마지막 답을 찾지 못함. jsonl 원본을 직접 확인)")
    sys.exit(0 if msg else 1)
