#!/usr/bin/env bash
# 만들기 전에 남들의 고민·삽질·표준·디자인 레퍼런스를 찾는다. 읽기 전용.
# 사용 (작업 폴더 루트에서): bash kit/scripts/research.sh <모델> <주제-이름> "<무엇을 하려는가>"
#   예: bash kit/scripts/research.sh "<모델 ID>" dedup "결제 재시도로 주문이 중복 생성되는 문제를 막고 싶다"
# 결과: notes/research-<주제>.jsonl (원본), notes/research-<주제>.md (보고)
set -euo pipefail

# ---- 설정
MODEL="${1:?모델 (/status에서 확인한 권장 모델)}"
TOPIC="${2:?주제 이름 (영문·숫자·_-)}"
GOAL="${3:?하려는 것 한 문장}"
OUT="notes/research-$TOPIC"

# ---- 준비
[[ "$TOPIC" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "주제 이름은 영문·숫자·_-만"; exit 1; }
[ -f kit/scripts/lastmsg.py ] || { echo "작업 폴더 루트에서 실행하세요"; exit 1; }
mkdir -p notes

# ---- 실행
PROMPT="하려는 것: $GOAL
이 고민을 우리만 한 게 아니다. 만들기 전에 선례를 찾아라. 파일은 고치지 마라.
1. 표준·널리 쓰는 해법 (이름, 핵심 규칙, 출처)
2. 남들이 밟은 함정과 기각된 대안 (출처)
3. 이 저장소 안의 이웃 코드·기존 테스트·변경 이력에서 맞춰야 할 관례 (파일 경로)
4. 화면이 있다면 참고할 만한 디자인 패턴 (출처 링크만. 이미지·코드를 복사하지 않는다)
5. 우리가 맞출 것 하나와 이유, 버릴 것과 이유
웹 검색을 쓸 수 있으면 쓰고, 못 쓰면 못 썼다고 적어라. 출처 없는 주장은 '추정'으로 표시한다. 40줄 이내."
codex exec -s read-only -m "$MODEL" -C . --json "$PROMPT" < /dev/null > "$OUT.jsonl"
python3 -B kit/scripts/lastmsg.py "$OUT.jsonl" > "$OUT.md" || true
cat "$OUT.md"
echo "저장: $OUT.md"
