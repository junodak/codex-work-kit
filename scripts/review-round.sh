#!/usr/bin/env bash
# 다관점 블라인드 리뷰 한 라운드. 관점마다 읽기 전용 Codex 세션을 병렬로 띄운다.
# 사용 (작업 폴더 루트에서): bash kit/scripts/review-round.sh <라운드명> <모델> [BASE]
#   예: bash kit/scripts/review-round.sh R1 <권장 모델>
# 결과: reviews/<라운드>/<관점>.jsonl (원본), <관점>.md (마지막 답), summary.md, triage.md (판정 양식)
set -euo pipefail

# ---- 설정
ROUND="${1:?라운드명 (예: R1)}"
MODEL="${2:?모델 (/status에서 확인한 권장 모델)}"
BASE="${3:-$(git rev-parse -q --verify work-base 2>/dev/null || git rev-list --max-parents=0 HEAD | tail -1)}"
KIT=kit/review
OUT="reviews/$ROUND"

# ---- 준비
[[ "$ROUND" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "라운드명은 영문·숫자·_-만"; exit 1; }
[ -d "$KIT/prompts" ] || { echo "작업 폴더 루트에서 실행하세요"; exit 1; }
[ -e "$OUT" ] && { echo "이미 있음: $OUT (라운드명을 바꾸세요)"; exit 1; }
mkdir -p "$OUT"
git rev-parse HEAD > "$OUT/HEAD.txt"
echo "$BASE" > "$OUT/BASE.txt"

# ---- 관점별 병렬 실행
pids=()
for p in "$KIT"/prompts/[0-9]-*.md; do
  name="$(basename "$p" .md)"
  prompt="$(cat "$KIT/prompts/common.md" "$p")
BASE=$BASE"
  ( codex exec -s read-only -m "$MODEL" -C . --json "$prompt" < /dev/null > "$OUT/$name.jsonl" 2> "$OUT/$name.err" \
      || echo "$name" >> "$OUT/failed.txt" ) &
  pids+=("$!")
  echo "시작: $name"
done
for pid in "${pids[@]}"; do wait "$pid" || true; done

# ---- 마지막 답 추출. 이벤트 형식은 버전마다 다를 수 있으니 원본 jsonl이 정본이다
python3 - "$OUT" << 'PY'
import json, re, sys, pathlib
out = pathlib.Path(sys.argv[1])
def count(text, grade):  # "등급: P1", "등급: **P1**" 모두 센다
    return len(re.findall(r"등급\W*" + grade + r"\b", text))
def texts(o):  # type/item_type, agent_message/assistant_message 모두 처리
    if isinstance(o, dict):
        kind = " ".join(str(o.get(k, "")) for k in ("type", "item_type", "kind", "role"))
        if ("message" in kind or "assistant" in kind) and "user" not in kind and isinstance(o.get("text"), str):
            yield o["text"]
        for v in o.values():
            yield from texts(v)
    elif isinstance(o, list):
        for v in o:
            yield from texts(v)
failed = (out / "failed.txt").read_text(encoding="utf-8").split() if (out / "failed.txt").exists() else []
parts, rows = [], []
for f in sorted(out.glob("*.jsonl")):
    last = ""
    for line in f.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            for t in texts(json.loads(line)):
                last = t
        except json.JSONDecodeError:
            pass
    last = last or "(마지막 답을 찾지 못함. jsonl 원본을 직접 확인)"
    (out / f"{f.stem}.md").write_text(last + "\n", encoding="utf-8")
    parts.append(f"## {f.stem}\n\n{last}\n")
    rows.append(f"| {f.stem} | {count(last, 'P1')} | {count(last, 'P2')} |")
head = (f"# 리뷰 요약\n\n실패한 관점: {len(failed)}개 {' '.join(failed)}\n\n"
        "| 관점 | P1 | P2 |\n|---|---|---|\n" + "\n".join(rows) + "\n\n"
        "같은 결함을 여러 관점이 낼 수 있다. 신규 여부와 채택은 triage.md에서 사람이 판정한다.\n\n")
(out / "summary.md").write_text(head + "\n".join(parts), encoding="utf-8")
PY
sed "s/라운드 R?/라운드 $ROUND/" "$KIT/triage.md" > "$OUT/triage.md"
echo "완료: $OUT/summary.md 를 읽고 $OUT/triage.md 에 판정을 적는다"
if [ -f "$OUT/failed.txt" ]; then echo "실패한 관점: $(tr '\n' ' ' < "$OUT/failed.txt")"; exit 2; fi
