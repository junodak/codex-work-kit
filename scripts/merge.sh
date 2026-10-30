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
[ -d "$WT" ] || { echo "워크트리 없음: $WT"; exit 1; }
[ -z "$(git status --porcelain -- . ':!.work' ':!reviews' ':!notes')" ] || { echo "주 브랜치에 커밋 안 된 변경이 있다. 먼저 정리하세요."; exit 1; }
TARGET="$(git branch --show-current)"

# ---- 게이트 1: 워크트리 검증
echo "== 게이트 1: $WT 에서 커밋 안 된 작업 변경 없음 + check.sh"
[ -z "$(git -C "$WT" status --porcelain -- . ':!reviews')" ] || { echo "실패: 워크트리에 커밋 안 된 변경이 있다. 커밋하거나 버린 뒤 다시."; exit 1; }
(cd "$WT" && bash kit/scripts/check.sh) || { echo "실패: 워크트리 검증. 병합하지 않는다."; exit 1; }

# ---- 게이트 2: 리뷰 판정 기록
if [ "$SKIP_REVIEW" != "--no-review" ]; then
  grep -lqs '판정 완료: \[x\]' "$WT"/reviews/*/triage.md || { echo "실패: 판정 완료된 리뷰 없음. (cd $WT && bash kit/scripts/review-round.sh R1 \"<모델>\") → triage.md 판정 후 '판정 완료: [x]'. 건너뛰려면 --no-review"; exit 1; }
fi
# 워크트리의 리뷰·검증 기록은 정리 전에 주 작업 폴더로 옮겨 보존한다
if [ -d "$WT/reviews" ]; then mkdir -p "reviews/merged-$NAME" && cp -R "$WT"/reviews/. "reviews/merged-$NAME/"; fi

# ---- 병합과 게이트 3
BEFORE="$(git rev-parse HEAD)"
git merge -q --no-ff "$BR" -m "merge $BR: 게이트 통과" || { git merge --abort 2>/dev/null; echo "실패: 병합 충돌. 되돌렸다. 워크트리에서 충돌 영역을 줄여 다시."; exit 1; }
echo "== 게이트 3: $TARGET 에서 check.sh"
if bash kit/scripts/check.sh; then
  # 남은 것은 위에서 옮긴 reviews/ 뿐이다 (게이트 1에서 확인)
  git worktree remove --force "$WT" && echo "병합 완료: $BR → $TARGET, 워크트리 정리 (기록: reviews/merged-$NAME)"
else
  git reset -q --hard "$BEFORE"
  echo "실패: 병합 후 검증. 병합을 되돌렸다 ($TARGET = $(git rev-parse --short HEAD)). 워크트리는 남겨 둔다."
  exit 1
fi
