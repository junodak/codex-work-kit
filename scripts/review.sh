#!/usr/bin/env bash
# 빠른 블라인드 리뷰 1회. 읽기 전용 Codex 세션 하나.
# 사용 (작업 폴더 루트에서): bash kit/scripts/review.sh <모델> [BASE]
# 결과: reviews/review-<시각>.jsonl (원본). 마지막 답이 리뷰 결과
set -euo pipefail

# ---- 설정
MODEL="${1:?모델 이름 (/status에서 확인한 권장 모델)}"
BASE="${2:-$(git rev-parse -q --verify work-base 2>/dev/null || git rev-list --max-parents=0 HEAD | tail -1)}"
OUT="reviews/review-$(date -u +%Y%m%dT%H%M%SZ).jsonl"

# ---- 준비
[ -d kit/review ] || { echo "작업 폴더 루트에서 실행하세요"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "git 저장소가 아니다. 먼저 kit/scripts/setup.sh"; exit 1; }
mkdir -p reviews

# ---- 실행
PROMPT="$(cat kit/review/prompts/common.md)
관점: 전체. 요구 위반과 틀린 결과를 우선 찾아라.
BASE=$BASE"
codex exec -s read-only -m "$MODEL" -C . --json "$PROMPT" < /dev/null > "$OUT"
echo "저장: $OUT"
