#!/usr/bin/env bash
# 제출 전 이해 점검: 내 변경과 기록에서 나올 법한 설명 질문 6개를 뽑는다. 답은 주지 않는다.
# 제출 뒤 서술형에서는 AI를 쓰지 않는다. 이 스크립트는 제출 전에만 쓴다.
# 사용 (작업 폴더 루트에서): bash kit/scripts/self-quiz.sh <모델>
# 결과: reviews/quiz-<시각>.jsonl (원본), reviews/quiz-<시각>.md (질문)
set -euo pipefail

# ---- 설정
MODEL="${1:?모델 (/status에서 확인한 권장 모델)}"
BASE="$(git rev-parse -q --verify work-base 2>/dev/null || git rev-list --max-parents=0 HEAD | tail -1)"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="reviews/quiz-$STAMP"

# ---- 준비
[ -f kit/scripts/lastmsg.py ] || { echo "작업 폴더 루트에서 실행하세요"; exit 1; }
mkdir -p reviews

# ---- 실행
PROMPT="너는 이 작업의 결과물을 받은 평가자다. 과제 안내(README 등), PLAN.md, DECISIONS.md,
그리고 git diff $BASE..HEAD -- . ':!kit' 를 읽어라. 파일은 고치지 마라.
작성자가 AI 없이 5분 안에 답해야 할 설명 질문 6개를 만들어라.
- 업무 조건과 선택의 이유, 실제 코드 경로, 검증 방법, 버린 대안, 남은 한계를 고르게 묻는다.
- 그중 하나는 실제 구현과 다른 전제를 깐 질문으로 만든다 (작성자가 바로잡아야 하는 질문).
- 질문만 번호로 쓴다. 답이나 힌트는 쓰지 않는다."
codex exec -s read-only -m "$MODEL" -C . --json "$PROMPT" < /dev/null > "$OUT.jsonl"
python3 -B kit/scripts/lastmsg.py "$OUT.jsonl" > "$OUT.md" || true
cat "$OUT.md"
echo "저장: $OUT.md  (질문마다 5분, AI 없이 직접 답해 본다)"
