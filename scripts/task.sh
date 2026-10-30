#!/usr/bin/env bash
# 독립된 일 하나를 git 워크트리에서 Codex에게 맡긴다. 여러 개를 동시에 띄울 수 있다.
# 사용 (작업 폴더 루트에서): bash kit/scripts/task.sh <모델> <작업-이름> "<지시>"
#   예: bash kit/scripts/task.sh "<모델 ID>" api "PLAN.md의 R1·R2를 만족하는 API를 구현하고 테스트를 추가해"
# 결과: .work/<이름> (워크트리, 브랜치 task/<이름>), reviews/task-<이름>.jsonl (작업 기록)
# 워크트리를 점(.) 폴더에 두는 이유: 주 작업 폴더의 테스트 도구(node --test, pytest)가 워크트리 테스트까지 재귀로 돌리지 않게.
# Codex는 파일만 고치고, 커밋은 이 스크립트가 한다 (샌드박스가 워크트리 밖 .git에 못 쓸 수 있다).
set -euo pipefail

# ---- 설정
MODEL="${1:?모델 (/status에서 확인한 권장 모델)}"
NAME="${2:?작업 이름 (영문·숫자·_-)}"
TASK="${3:?지시}"
WT=".work/$NAME"
BR="task/$NAME"
LOG="reviews/task-$NAME.jsonl"

# ---- 준비
[[ "$NAME" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "작업 이름은 영문·숫자·_-만"; exit 1; }
[ -f kit/scripts/lastmsg.py ] || { echo "작업 폴더 루트에서 실행하세요"; exit 1; }
[ -e "$WT" ] && { echo "이미 있음: $WT"; exit 1; }
for f in PLAN.md AGENTS.md DECISIONS.md; do
  [ -z "$(git status --porcelain -- "$f" 2>/dev/null)" ] || { echo "중단: $f 가 커밋되지 않았다. 워크트리는 커밋된 상태만 본다. 먼저 커밋하세요."; exit 1; }
done
# 워크트리·의존성·캐시·비밀 파일은 커밋하지 않는다 (모든 워크트리가 공유하는 제외 목록)
for pat in .work/ node_modules .venv venv __pycache__ '*.pyc' .env; do
  grep -qxF "$pat" .git/info/exclude 2>/dev/null || echo "$pat" >> .git/info/exclude
done
mkdir -p .work reviews
git worktree add -q -b "$BR" "$WT" HEAD
echo "워크트리: $WT (브랜치 $BR, 기준 $(git rev-parse --short HEAD))"
# 주 폴더의 설치된 의존성을 워크트리에서 쓰게 링크한다 (새 checkout에는 없다)
for dep in node_modules .venv venv; do
  if [ -d "$dep" ] && [ ! -e "$WT/$dep" ]; then ln -s "$(pwd)/$dep" "$WT/$dep"; echo "의존성 링크: $WT/$dep"; fi
done

# ---- 실행 (작업 폴더 안에서만 쓰기)
PROMPT="이 워크트리에서 아래 작업만 한다. AGENTS.md와 PLAN.md를 먼저 읽어라.
작업: $TASK
- 이 작업 범위 밖의 파일은 고치지 마라. git 명령(commit, branch 등)은 쓰지 마라. 커밋은 바깥에서 한다.
- 관련 테스트를 추가하거나 고치고, 실행해서 결과를 확인해라.
- 끝나면 변경 파일, 실행한 명령과 결과, 남은 조건만 짧게 보고해라."
set +e
codex exec -s workspace-write -m "$MODEL" -C "$WT" --json "$PROMPT" < /dev/null > "$LOG" 2> "${LOG%.jsonl}.err"
rc=$?
set -e
python3 -B kit/scripts/lastmsg.py "$LOG" | tail -20 || true

# ---- 커밋 (kit/는 검사기다. 작업이 고친 kit 변경은 되돌린다)
if [ -n "$(git -C "$WT" status --porcelain --ignored -- kit)" ]; then
  git -C "$WT" checkout -q -- kit && git -C "$WT" clean -qfdx -- kit
  echo "경고: 작업이 kit/를 고쳤다. 되돌렸다 (검사기는 작업이 바꾸지 않는다)"
fi
if [ -n "$(git -C "$WT" status --porcelain -- . ':!reviews')" ]; then
  # 제외 목록을 .gitignore가 뒤집을 수 있어서(!.env) 커밋 경로에서도 직접 뺀다
  git -C "$WT" add -A -- . ':!reviews'
  for p in .env node_modules .venv venv; do  # 원래 추적하던 파일이 아니면 커밋에서 뺀다
    [ -n "$(git -C "$WT" ls-tree HEAD -- "$p")" ] || git -C "$WT" rm -r -q --cached --ignore-unmatch -- "$p"
  done
  SUMMARY="$(python3 -B -c 'import sys; t=" ".join(sys.argv[1].split()); print(t[:50] + ("…" if len(t) > 50 else ""))' "$TASK")"  # 글자 단위로 자른다 (한글이 깨지지 않게)
  git -C "$WT" commit -q -m "$NAME: $SUMMARY"
  echo "커밋: $(git -C "$WT" log -1 --oneline)"
else
  echo "변경 없음"
fi
echo "codex 종료 코드: $rc. 다음: (cd $WT && bash kit/scripts/check.sh) → 리뷰 → bash kit/scripts/merge.sh $NAME"
exit $rc
