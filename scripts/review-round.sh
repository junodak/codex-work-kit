#!/usr/bin/env bash
# 다관점 블라인드 리뷰 한 라운드. 관점마다 읽기 전용 Codex 세션을 병렬로 띄운다.
# 사용 (작업 폴더 루트에서): bash kit/scripts/review-round.sh <라운드명> <모델> [BASE]
#   예: bash kit/scripts/review-round.sh R1 <권장 모델>
# 결과: reviews/<작업>/<라운드>/ 아래 <관점>.jsonl (원본), <관점>.md (마지막 답), summary.md, triage.md (판정 양식)
#   <작업>은 브랜치 task/<작업>의 이름, 주 브랜치면 그 브랜치 이름. 기록은 커밋해서 산출물로 남긴다
set -euo pipefail

# ---- 설정
ROUND="${1:?라운드명 (예: R1)}"
MODEL="${2:?모델 (/status에서 확인한 권장 모델)}"
# 기준: 인자 > (워크트리면) 주 브랜치와의 merge-base = 이 작업의 변경만 > work-base > 첫 커밋
fork_point() {  # task.sh가 워크트리에 기록한 병합 대상 브랜치와의 merge-base
  local f; f="$(git rev-parse --absolute-git-dir)/kit-target"
  [ -f "$f" ] && git merge-base HEAD "$(cat "$f")"
}
BASE="${3:-$(fork_point 2>/dev/null || git rev-parse -q --verify work-base 2>/dev/null || git rev-list --max-parents=0 HEAD | tail -1)}"
KIT=kit/review
SCOPE="$(git branch --show-current)"; SCOPE="${SCOPE#task/}"; SCOPE="${SCOPE:-detached}"
OUT="reviews/$SCOPE/$ROUND"  # 작업별 폴더: 병합 뒤 다음 워크트리가 물려받아도 겹치지 않는다

# ---- 준비
git rev-parse -q --verify "$BASE^{commit}" >/dev/null || { echo "BASE가 커밋이 아니다: $BASE (모델 이름에 공백이 있으면 따옴표로 감싼다)"; exit 1; }
[ "$(git rev-parse "$BASE^{commit}")" != "$(git rev-parse HEAD)" ] || { echo "중단: 리뷰할 변경이 없다 (BASE = HEAD). 워크트리 작업이면 .work/<이름> 안에서, 주 폴더면 커밋한 뒤 실행한다."; exit 1; }
[ -z "$(git status --porcelain --untracked-files=no)" ] || echo "주의: 커밋 안 된 변경이 있다. 리뷰는 커밋된 HEAD만 본다."
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
  if [ -n "${ONLY:-}" ] && ! echo " $ONLY " | grep -q " ${name%%-*} "; then continue; fi  # ONLY="1 2" 로 관점만 골라 돌린다
  prompt="$(cat "$KIT/prompts/common.md" "$p")
BASE=$BASE"
  ( codex exec -s read-only -m "$MODEL" -C . --json "$prompt" < /dev/null > "$OUT/$name.jsonl" 2> "$OUT/$name.err" \
      || echo "$name" >> "$OUT/failed.txt" ) &
  pids+=("$!")
  echo "시작: $name"
done
[ ${#pids[@]} -gt 0 ] || { echo "실패: 돌린 관점이 없다 (ONLY=\"${ONLY:-}\"). 예: ONLY=\"1 2\""; exit 1; }
for pid in "${pids[@]}"; do wait "$pid" || true; done

# ---- 마지막 답 추출 (kit/scripts/lastmsg.py). 원본 jsonl이 정본이다
python3 -B - "$OUT" << 'PY'
import re, sys, pathlib
sys.path.insert(0, "kit/scripts")
from lastmsg import last_message
out = pathlib.Path(sys.argv[1])
def count(text, grade):  # "등급: P1", "등급: **P1**" 모두 센다
    return len(re.findall(r"등급\W*" + grade + r"(?![0-9])", text))
failed = (out / "failed.txt").read_text(encoding="utf-8").split() if (out / "failed.txt").exists() else []
parts, rows = [], []
for f in sorted(out.glob("*.jsonl")):
    last = last_message(f) or "(마지막 답을 찾지 못함. jsonl 원본을 직접 확인)"
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
if [ -f "$OUT/failed.txt" ]; then
  echo "실패한 관점: $(tr '\n' ' ' < "$OUT/failed.txt")"
  for n in $(cat "$OUT/failed.txt"); do echo "--- $n 이유:"; tail -3 "$OUT/$n.err"; done
  echo "모델 ID 문제면 고쳐서, 일시 오류면 그대로 새 라운드명(R2)으로 다시"
  exit 2
fi
