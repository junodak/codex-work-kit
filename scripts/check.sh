#!/usr/bin/env bash
# 매 단계 같은 명령으로 재검증한다: 테스트 + 변경 상태.
# 사용 (작업 폴더 루트에서): bash kit/scripts/check.sh
# 종료 코드는 테스트 결과를 따른다.
set -uo pipefail

BASE="$(git rev-parse -q --verify work-base 2>/dev/null || true)"
rc=0
mkdir -p reviews
run() { echo "\$ $*"; "$@"; rc=$?; }

# ---- 테스트 (발견한 것 하나만 실행)
if [ -f package.json ] && grep -q '"test"' package.json; then
  run npm test --silent
elif [ -f pyproject.toml ] || [ -f pytest.ini ] || ls tests/*.py test_*.py >/dev/null 2>&1; then
  if python3 -c "import pytest" 2>/dev/null; then run python3 -m pytest -q; else run python3 -m unittest discover -s tests -q; fi
elif [ -f go.mod ]; then
  run go test ./...
elif [ -f Makefile ] && grep -q '^test:' Makefile; then
  run make test
else
  echo "테스트 명령을 찾지 못함. 과제 안내에서 실행 방법을 확인한다."
fi
echo "테스트 종료 코드: $rc"

# ---- 서버 스모크 (선택): SMOKE_CMD로 띄우고 SMOKE_URL이 응답하는지만 본다
if [ -n "${SMOKE_CMD:-}" ] && [ -n "${SMOKE_URL:-}" ]; then
  echo "\$ (스모크) $SMOKE_CMD → $SMOKE_URL"
  bash -c "$SMOKE_CMD" > reviews/smoke-server.log 2>&1 &
  spid=$!
  code=000
  for _ in $(seq 1 30); do
    code=$(curl -s -o /dev/null -w '%{http_code}' "$SMOKE_URL" || true)
    [ "$code" != "000" ] && break
    sleep 1
  done
  kill "$spid" 2>/dev/null; pkill -P "$spid" 2>/dev/null; wait "$spid" 2>/dev/null
  echo "스모크 응답: HTTP $code (서버 로그: reviews/smoke-server.log)"
  case "$code" in 2*|3*) ;; *) rc=1 ;; esac
fi

# ---- 변경 상태
echo "--- git status"
git status --short -- . ':!reviews'
if [ -n "$BASE" ]; then
  echo "--- work-base 이후 변경 (kit 제외)"
  git diff --stat "$BASE" -- . ':!kit' ':!reviews' | tail -5
fi
exit $rc
