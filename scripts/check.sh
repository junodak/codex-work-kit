#!/usr/bin/env bash
# 매 단계 같은 명령으로 재검증한다: 테스트 + 변경 상태.
# 사용 (작업 폴더 루트에서): bash kit/scripts/check.sh
# 종료 코드는 테스트 결과를 따른다.
set -uo pipefail

BASE="$(git rev-parse -q --verify work-base 2>/dev/null || true)"
rc=0
mkdir -p reviews
found=0
run() { echo "\$ $*"; "$@"; local r=$?; found=1; [ $r -eq 0 ] || rc=$r; }

# ---- 테스트 (찾은 러너를 전부 실행한다. 백엔드·화면이 다른 언어일 수 있다)
if [ -f package.json ] && grep -q '"test"' package.json; then
  # vitest·jest 설정에 따라 .work/(다른 워크트리)의 테스트까지 모을 수 있다
  if [ -d .work ] && grep -q vitest package.json && ! grep -rqs "\.work" vitest.config.* vite.config.* package.json; then
    echo "주의: vitest가 .work/의 다른 워크트리 테스트까지 돌 수 있다. 설정 test.exclude에 '.work/**' 를 넣는다."
  fi
  run npm test --silent
fi
if [ -f pyproject.toml ] || [ -f pytest.ini ] || [ -f setup.cfg ] || compgen -G 'tests/*.py' >/dev/null || compgen -G 'test_*.py' >/dev/null || compgen -G '*/test_*.py' >/dev/null; then
  PY=python3  # 작업 폴더의 가상환경이 있으면 그 python (설치한 pytest가 거기 있다)
  for v in .venv venv; do if [ -x "$v/bin/python" ]; then PY="$v/bin/python"; break; fi; done
  if "$PY" -c "import pytest" 2>/dev/null; then run "$PY" -m pytest -q
  elif grep -lqsE '^def test_' tests/*.py test_*.py */test_*.py 2>/dev/null; then
    # unittest는 pytest 형식 함수를 조용히 건너뛴다. 일부만 돌고 통과하는 것을 막는다
    found=1; rc=1; echo "실패: pytest 형식 테스트(def test_...)가 있는데 pytest가 없다. $PY -m pip install pytest"
  else  # pytest가 없으면 표준 unittest. 테스트가 tests/ 밖에 있을 수도 있다
    START=.; [ -d tests ] && START=tests
    echo "\$ $PY -m unittest discover -s $START"
    out="$("$PY" -m unittest discover -s "$START" 2>&1)"; r=$?; found=1
    echo "$out"
    # 버전에 따라 0개 실행을 통과로 끝낸다. 가짜 통과를 막는다
    if echo "$out" | grep -q '^Ran 0 tests'; then r=1; echo "unittest가 테스트를 0개 실행했다. pytest 형식 테스트면 pytest를 설치한다 ($PY -m pip install pytest)"; fi
    [ $r -eq 0 ] || rc=$r
  fi
fi
if [ -f go.mod ]; then
  run go test ./...
fi
if [ $found = 0 ] && [ -f Makefile ] && grep -q '^test:' Makefile; then
  run make test
fi
if [ $found = 0 ]; then
  echo "테스트 명령을 찾지 못함. 과제 안내에서 실행 방법을 확인한다."
  if [ "${NO_TESTS:-}" = 1 ]; then echo "NO_TESTS=1: 테스트 없이 통과로 둔다"; else rc=1; echo "실패로 처리한다 (테스트가 정말 없으면 NO_TESTS=1)"; fi
fi
echo "테스트 종료 코드: $rc"

# ---- 서버 스모크 (선택): SMOKE_CMD로 띄우고 SMOKE_URL이 응답하는지만 본다
if [ -n "${SMOKE_CMD:-}" ] && [ -n "${SMOKE_URL:-}" ]; then
  echo "\$ (스모크) $SMOKE_CMD → $SMOKE_URL"
  code=000
  if [ "$(curl -s -o /dev/null -w '%{http_code}' "$SMOKE_URL" || true)" != 000 ]; then
    echo "실패: 띄우기 전에 이미 $SMOKE_URL 이 응답한다 (다른 서버가 포트를 쓰는 중). 그 서버를 끄거나 다른 포트로."; rc=1
  else
    bash -c "$SMOKE_CMD" > reviews/smoke-server.log 2>&1 &
    spid=$!
    for _ in $(seq 1 30); do
      kill -0 "$spid" 2>/dev/null || { echo "서버가 뜨다가 종료됐다"; break; }
      code=$(curl -s -o /dev/null -w '%{http_code}' "$SMOKE_URL" || true)
      [ "$code" != "000" ] && break
      sleep 1
    done
  fi
  [ -n "${spid:-}" ] && { kill "$spid" 2>/dev/null; pkill -P "$spid" 2>/dev/null; wait "$spid" 2>/dev/null; }
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
