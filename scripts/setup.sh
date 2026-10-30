#!/usr/bin/env bash
# 키트를 작업 폴더에 흡수하고 바로 작업할 수 있게 만든다.
# 작업 폴더 루트에서:
#   git clone --depth 1 https://github.com/junodak/codex-work-kit kit && bash kit/scripts/setup.sh
set -euo pipefail

# ---- 설정
KIT=kit
FILES=(AGENTS.md PLAN.md DECISIONS.md)
BASE_TAG=work-base   # 리뷰 diff의 기준: 키트 추가 직후, 내 작업 직전

# ---- 준비
[ -f "$KIT/scripts/setup.sh" ] || { echo "작업 폴더 루트에서 실행하세요 (키트는 ./$KIT)"; exit 1; }
ensure_identity() {
  git config user.name  >/dev/null 2>&1 || { git config user.name  "candidate"; echo "git 로컬 신원 설정: candidate"; }
  git config user.email >/dev/null 2>&1 || git config user.email "candidate@localhost"
}
exclude_local() {  # 워크트리·의존성·캐시·비밀 파일은 커밋하지 않는다 (모든 워크트리가 공유하는 제외 목록)
  local ex; ex="$(git rev-parse --git-path info/exclude)"; mkdir -p "$(dirname "$ex")"  # .git이 파일이거나 상위 폴더에 있어도
  for pat in .work/ node_modules .venv venv __pycache__ '*.pyc' .env; do
    grep -qxF "$pat" "$ex" 2>/dev/null || echo "$pat" >> "$ex"
  done
}
place() {  # 기존 파일은 덮어쓰지 않는다
  if [ -e "$2" ]; then echo "있음, 건너뜀: $2"; else cp "$1" "$2"; echo "배치: $2"; fi
}

# ---- 1. 흡수: 중첩 저장소를 만들지 않는다
if [ -d "$KIT/.git" ]; then rm -rf "$KIT/.git"; echo "흡수: $KIT/.git 제거"; fi

# ---- 2. 저장소가 없으면 주어진 상태 그대로 baseline (키트·의존성·비밀 파일 제외)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && [ "$(git rev-parse --show-toplevel)" != "$(pwd -P)" ]; then
  echo "중단: 이 폴더는 상위 git 저장소($(git rev-parse --show-toplevel))의 하위 폴더다. 과제 저장소의 루트에서 실행한다."; exit 1
fi
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init -q
  ensure_identity
  exclude_local
  # 무시된 경로를 pathspec으로 지목하면 git이 오류를 낸다. 전부 add한 뒤 의존성·비밀 파일만 index에서 뺀다
  git add -A -- . ":!$KIT"
  git rm -r -q --cached --ignore-unmatch -- node_modules .env .venv venv
  git commit -q --allow-empty -m "baseline: 주어진 상태 그대로"
  echo "git init + baseline 커밋 (node_modules·.env·venv 제외)"
else
  ensure_identity
  exclude_local
  if [ -n "$(git diff --cached --name-only)" ]; then
    echo "주의: 이미 stage된 변경이 있다. 키트 커밋에는 넣지 않고 그대로 둔다."
  fi
fi

# ---- 3. 지침·양식 배치
HAD_AGENTS=0; [ -e AGENTS.md ] && HAD_AGENTS=1
place "$KIT/AGENTS.md" AGENTS.md
place "$KIT/templates/PLAN.md" PLAN.md
place "$KIT/templates/DECISIONS.md" DECISIONS.md
mkdir -p reviews
if [ "$HAD_AGENTS" = 1 ] && ! grep -q "kit/AGENTS.md" AGENTS.md; then
  echo "안내: 기존 AGENTS.md가 있다. 끝에 다음 줄을 추가할지 판단하세요:"
  echo "      - 작업 원칙은 kit/AGENTS.md 도 따른다."
fi

# ---- 4. 키트와 양식만 커밋 (다른 stage 변경은 섞지 않는다)
git add -- "$KIT" "${FILES[@]}"
if git diff --cached --quiet -- "$KIT" "${FILES[@]}"; then
  echo "커밋할 키트 변경 없음"
else
  git commit -q -m "작업 키트와 기록 양식 추가" -- "$KIT" "${FILES[@]}"
  echo "커밋: 작업 키트와 기록 양식 추가"
fi
git tag -f "$BASE_TAG" >/dev/null
echo "리뷰 기준 태그: $BASE_TAG ($(git rev-parse --short HEAD))"

# ---- 5. 요약
git log --oneline | head -3
echo "실행 환경 시간: $(date '+%Y-%m-%d %H:%M %Z')  (업무 기준 시간대와 다르면 kit/checklists.md 날짜 절)"
echo "다음: kit/RUNBOOK.md 시간표대로"
