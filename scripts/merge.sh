#!/usr/bin/env bash
# 워크트리 작업을 게이트를 통과할 때만 main에 병합한다. 실패하면 병합을 되돌린다.
# 사용 (작업 폴더 루트에서, 주 브랜치에 있을 때): bash kit/scripts/merge.sh <작업-이름> [--no-review]
# 게이트: 1) 워크트리가 깨끗하고 check.sh 통과  2) 리뷰 판정 완료 표시(.work/<이름>/reviews/*/triage.md 의 '판정 완료: [x]')
#         3) 병합 후 주 브랜치에서 check.sh 통과
set -euo pipefail

# ---- 설정
NAME="${1:?작업 이름}"
SKIP_REVIEW="${2:-}"
WT=".work/$NAME"
BR="task/$NAME"

# ---- 준비
[ "$(git rev-parse --git-dir)" = "$(git rev-parse --git-common-dir)" ] || { echo "주 작업 폴더 루트에서 실행한다 (지금 위치: $(pwd)). 워크트리 안이면 cd 로 루트로."; exit 1; }
[ -d "$WT" ] || { echo "워크트리 없음: $WT"; exit 1; }
# 실패 시 reset --hard로 되돌리므로 tracked 변경은 하나도 없어야 한다. 새 파일은 .work·reviews·notes 아래만 허용
[ -z "$(git status --porcelain --untracked-files=no)" ] && [ -z "$(git status --porcelain -- . ':!.work' ':!reviews' ':!notes')" ] \
  || { echo "주 브랜치에 커밋 안 된 변경이 있다. 필요한 변경(의존성의 package.json·lock 등)은 커밋하고, 아니면 되돌린 뒤 다시:"; git status --short -- . ':!.work' ':!reviews' ':!notes' | head -10; exit 1; }
TARGET="$(git branch --show-current)"
[ -n "$TARGET" ] || { echo "중단: 주 폴더가 브랜치 위에 있지 않다(분리 HEAD). git switch <주 브랜치> 뒤 다시."; exit 1; }
WANT="$(cat "$(git -C "$WT" rev-parse --absolute-git-dir)/kit-target" 2>/dev/null || true)"
[ -z "$WANT" ] || [ "$WANT" = "$TARGET" ] || { echo "중단: $NAME 은 $WANT 에서 갈라졌는데 지금 주 폴더는 $TARGET 이다. git switch $WANT 뒤 다시."; exit 1; }
ROOT="$(pwd)"
# 검사기(kit/)는 작업 브랜치가 바꿀 수 없다. 바꿨다면 게이트가 바뀐 검사기로 돌게 된다
git diff --quiet "HEAD...$BR" -- kit || { echo "실패: $BR 이 kit/를 고쳤다. 검사기 변경은 병합하지 않는다."; exit 1; }

# ---- 게이트 1: 워크트리 검증
echo "== 게이트 1: $WT 에서 커밋 안 된 작업 변경 없음 + check.sh"
[ -z "$(git -C "$WT" status --porcelain -- . ':!reviews')" ] || { echo "실패: 워크트리에 커밋 안 된 변경이 있다. 커밋하거나 버린 뒤 다시."; exit 1; }
[ -z "$(git -C "$WT" status --porcelain --ignored -- kit)" ] || { echo "실패: 워크트리의 kit/에 원본과 다른 파일이 있다. 검사기는 작업이 바꾸지 않는다."; exit 1; }
for dep in node_modules .venv venv; do  # task.sh가 만든 의존성 링크가 주 폴더를 가리키는지
  if [ -e "$dep" ] && [ -e "$WT/$dep" ] && { [ ! -L "$WT/$dep" ] || [ "$(readlink "$WT/$dep")" != "$ROOT/$dep" ]; }; then
    echo "실패: $WT/$dep 가 주 폴더의 $dep 링크가 아니다."; exit 1
  fi
done
(cd "$WT" && bash "$ROOT/kit/scripts/check.sh") || { echo "실패: 워크트리 검증. 병합하지 않는다."; exit 1; }  # 주 폴더의 검사기로

# ---- 게이트 2: 리뷰 판정 기록
if [ "$SKIP_REVIEW" != "--no-review" ]; then
  # 판정 완료 표시가 있고, 그 라운드가 리뷰한 커밋이 지금 브랜치 HEAD와 같아야 한다 (판정 뒤 수정했으면 다시 리뷰)
  TIP="$(git rev-parse "$BR")"; fresh=""
  for t in "$WT"/reviews/*/triage.md; do
    [ -f "$t" ] || continue
    d="$(dirname "$t")"
    [ -f "$d/HEAD.txt" ] && [ ! -L "$d/HEAD.txt" ] || continue  # 링크는 받지 않는다 (항상 현재 HEAD를 가리킬 수 있다)
    grep -q '판정 완료: \[x\]' "$t" && [ "$(cat "$d/HEAD.txt")" = "$TIP" ] && fresh="$d"
  done
  [ -n "$fresh" ] || { echo "실패: 현재 HEAD($(git rev-parse --short "$BR"))를 리뷰하고 판정 완료한 라운드가 없다. 판정 뒤 고쳤으면 새 라운드(R2 등)로 다시 리뷰 → triage.md 판정 → '판정 완료: [x]'. 건너뛰려면 --no-review"; exit 1; }
  echo "판정 확인: $fresh"
fi
# 워크트리의 리뷰·검증 기록은 정리 전에 주 작업 폴더로 옮겨 보존한다
if [ -d "$WT/reviews" ]; then mkdir -p "reviews/merged-$NAME" && cp -R "$WT"/reviews/. "reviews/merged-$NAME/"; fi

# ---- 병합과 게이트 3
BEFORE="$(git rev-parse HEAD)"
git merge -q --no-ff "$BR" -m "merge $BR: 게이트 통과" || { git merge --abort 2>/dev/null; echo "실패: 병합 충돌. 되돌렸다. 복구: (cd $WT && git merge $TARGET) → 충돌 해결 → git commit → 새 라운드(R2) 리뷰·판정 → 다시 merge.sh"; exit 1; }
echo "== 게이트 3: $TARGET 에서 check.sh"
if bash kit/scripts/check.sh; then
  # 커밋은 이미 병합됐다. 워크트리에 남은 것은 위에서 옮긴 reviews/와 check.sh 산출물, 의존성 링크뿐이다
  if git worktree remove --force "$WT"; then
    echo "병합 완료: $BR → $TARGET, 워크트리 정리 (기록: reviews/merged-$NAME). 같은 이름은 다시 쓰지 않는다"
  else
    echo "병합은 완료. 워크트리 정리 실패: $WT 를 직접 확인하세요"
  fi
else
  git reset -q --hard "$BEFORE"  # 시작 때 tracked 변경이 없음을 확인했다. 커밋 안 된 새 파일(notes 등)은 남는다
  echo "실패: 병합 후 검증. 병합을 되돌렸다 ($TARGET = $(git rev-parse --short HEAD)). 워크트리는 남겨 둔다."
  exit 1
fi
