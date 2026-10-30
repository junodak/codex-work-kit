# codex-work-kit

Codex로 짧은 업무 과제(기존 코드 수정, 작은 도구 제작)를 할 때 쓰는 개인 작업 지침, 방법론, 문서 템플릿이다.

- 작성: 2026-10-30~31, 개인 작업 원칙을 일반화해 정리함
- **특정 과제의 답안이나 코드는 들어 있지 않다.** 외부 저장소의 내용도 복사하지 않고 링크만 둔다.

## 무엇인가: 검증 중심의 1인 소프트웨어 조직

사람이 보는 대상은 코드에서 **의도**로 옮겨 가고 있다. 이 키트의 진짜 산출물은 코드가 아니라, 의도가 거짓 없이 결과로 닫히는 **파이프라인**이다. 사람은 의도를 정하고 판정하며, 실행과 반증은 에이전트가 맡는다.

| 역할 | 산출물 | 누가 |
|---|---|---|
| 요구 확인 | `PLAN.md` 조건표 (조건·출처·완료 기준) | 사람이 묻고 고정, 에이전트가 정리 |
| 선례 조사 | `notes/research-<주제>.md` 표준·함정·이웃 코드·디자인 패턴 (출처) | 읽기 전용 에이전트 |
| 구현 | 작은 단위 커밋. 병렬이면 워크트리별 브랜치 `task/<이름>` | 주 세션 또는 워크트리마다 한 세션 |
| 검증 | 조건별 실행 결과 (`checklists.md`) | 에이전트가 실행, 사람이 화면 확인 |
| 리뷰 | `reviews/<라운드>/` 4관점 블라인드 결과 | 읽기 전용 에이전트들, 서로 독립 |
| 판정·병합 | `triage.md` 채택·기각과 재확인 근거, 게이트를 통과한 병합 커밋 | 사람이 판정, 스크립트가 게이트 |
| 기록 | `DECISIONS.md` 결정·대안·근거·한계·정정 | 에이전트가 쓰고 사람이 대조 |

- 모든 단계가 작업 폴더의 파일과 git 이력으로 남는다. 임시 경로를 쓰지 않는다.
- 사람은 코드를 덜 읽지만 이해를 놓지 않는다. 핵심 코드 경로는 직접 읽고 자기 말로 설명할 수 있어야 한다.

## 쓰는 법

작업 폴더 루트에서 한 줄:

```bash
git clone --depth 1 https://github.com/junodak/codex-work-kit kit && bash kit/scripts/setup.sh
```

`setup.sh`가 하는 일:
- `kit/.git`을 지워 키트를 작업 이력에 흡수한다 (중첩 저장소를 만들지 않는다).
- git 저장소가 없으면 주어진 상태 그대로 baseline 커밋을 만든다.
- `AGENTS.md`, `PLAN.md`, `DECISIONS.md`를 루트에 둔다. 기존 파일은 덮어쓰지 않는다.
- 키트와 양식만 커밋하고, 실행 환경 시간대를 보여 준다.

임시 경로를 쓰지 않는다. 키트, 기록, 리뷰 결과가 모두 작업 폴더 안에 남는다.

- 전제: git, bash, python3, Codex CLI, GitHub 접근. git 신원이 없으면 로컬에 `candidate`로 설정한다.
- 리뷰 diff의 기준으로 `work-base` 태그를 단다 (키트 추가 직후).
- 설치 후 경로는 모두 `kit/` 아래다 (`kit/RUNBOOK.md` 등).
- **다음: `kit/RUNBOOK.md` 시간표대로 진행한다.**

## 지도

| 파일 | 언제 읽나 |
|---|---|
| `AGENTS.md` | 항상 (작업 원칙) |
| `RUNBOOK.md` | 시작할 때: 180분 시간 배분, 병렬·컨텍스트·권한 규칙 |
| `checklists.md` | 요구 확인, 날짜·시간대, 조건별 검증, 제출 전 |
| `prompts.md` | 위임·리뷰 요청문, 담당자 질문, 설명 답변 틀 |
| `templates/` | PLAN.md(조건표), DECISIONS.md(판단·정정 기록) |
| `scripts/setup.sh` | 처음 한 번: 키트 흡수, baseline, 양식 배치, 커밋 |
| `scripts/check.sh` | 매 단계 같은 명령으로 재검증: 테스트(npm·pytest·go·make 자동 감지) + 변경 상태. `SMOKE_CMD`·`SMOKE_URL`을 주면 서버 응답도 확인 |
| `scripts/self-quiz.sh` | 제출 전 이해 점검: 내 변경에서 설명 질문 6개를 뽑는다 (답 없음) |
| `scripts/lastmsg.py` | `codex exec --json` 결과에서 마지막 답 추출 |
| `scripts/research.sh` | 만들기 전 선례 조사: 표준, 함정, 이웃 코드 관례, 디자인 패턴 → `notes/` |
| `scripts/task.sh` | 독립된 일을 워크트리(`work/<이름>`)에서 Codex에게 맡기고 커밋 |
| `scripts/merge.sh` | 게이트(워크트리 깨끗함·check 통과·리뷰 판정, 병합 후 check) 통과 시에만 병합, 실패하면 되돌림 |
| `scripts/review.sh` | 빠른 리뷰 1회: 읽기 전용 별도 세션 하나. 결과는 `reviews/` |
| `scripts/review-round.sh` | 다관점 블라인드 리뷰 한 라운드: 관점 4개(동작·실패 경로·정합·필요성)를 읽기 전용으로 병렬 실행 → `reviews/<라운드>/summary.md`, `triage.md` |
| `review/` | 리뷰 프롬프트(라운드마다 같은 문장으로 고정)와 판정 양식 |
| `docs/philosophy.md` | 판단이 막힐 때: 어디까지 파고 언제 멈추나 |
| `docs/sot-principles.md` | 근거·기록을 다룰 때: 원천과 파생, 한 사실 한 곳 |
| `docs/methods.md` | 방법이 필요할 때: 리뷰 루프, 재현 테스트, before/after 등 |
| `docs/web-service.md` | 작은 웹서비스를 만들 때: 스택 고르기, 순서, 구조, 화면 확인 체크리스트, 함정 |
| `docs/codex-notes.md` | Codex CLI 실전 노트: 처음 5분, exec 옵션, 함정, 컨텍스트 |
| `docs/harness-map.md` | 외부 하네스·스킬이 필요할 때: 무엇을 clone할지 |
| `docs/mcp-example.json` | 키 없는 문서 조회 MCP 예시. 기본은 쓰지 않는다 (외부 패키지를 받음, 동작 미확인) |
| `LICENSE` | MIT |
