# 공개 하네스·스킬·지침 저장소 지도 (지도만 있고 내용은 없음)
쓰는 법: 필요한 것만 `git clone --depth 1`, 통째로 결과물에 넣지 않는다, 복사·재배포 전 LICENSE 확인(라이선스 칸이 비어 있으면 저장소에 SPDX 표기가 없다는 뜻이니 LICENSE 파일을 직접 열어 본다).
확인 날짜: 2026-10-31 (GitHub API로 존재·스타·라이선스·최근 push 확인. 스타 수는 대략치이며 계속 변한다)

## 1. 전체 표
| 이름 | 저장소 URL | 무엇에 쓰나 | Codex에서 쓰는 법 | 라이선스 | 확인 상태 |
|---|---|---|---|---|---|
| superpowers | https://github.com/obra/superpowers | 브레인스토밍→계획→TDD→리뷰로 이어지는 개발 방법론 스킬 모음 | `skills/` 읽기 후 필요한 스킬 폴더만 참고, `.codex-plugin` 있음 | MIT | 확인 (약 309k★, 10/29 push) |
| gstack | https://github.com/garrytan/gstack | Garry Tan의 Claude Code 셋업, 역할별(CEO·설계·QA·릴리스) 스킬 23종 | 루트 `AGENTS.md`와 스킬 폴더 읽기, `codex/` 폴더 존재 | MIT | 확인 (약 138k★, 10/30 push) |
| pstack (원본, Cursor) | https://github.com/cursor/plugins/tree/main/pstack | Poteto(Lauren Tan)의 엄밀한 AI 엔지니어링 스킬·원칙 모음 | `skills/` 읽기 | 하위에 LICENSE 파일 있음(종류 미확인) | 확인 (cursor/plugins 약 14.7k★) |
| pstack 미러 | https://github.com/backnotprop/pstack | 위 pstack의 단독 미러, Claude·Codex·Pi 등에 설치 | `skills/` 읽기 또는 복사 | MIT | 확인 (약 3.2k★, 10/28 push) |
| pstack-claude | https://github.com/michael-denyer/pstack-claude | pstack을 Claude Code·Codex·Copilot 등으로 옮긴 판 | 읽기만 | MIT | 확인 (약 3.7k★) |
| pstack-for-codex | https://github.com/Aqua-123/pstack-for-codex | pstack 기반 Codex 전용 워크플로 45 스킬 | 읽기, Codex 구조 참고 | 미확인 | 확인 (약 100★, 비공식 파생) |
| Anthropic Skills | https://github.com/anthropics/skills | Anthropic 공식 Agent Skills 예시와 스펙·템플릿 | `spec/`·`template/` 참고, 스킬 구조 읽기 | 저장소 단위 SPDX 없음(스킬별 LICENSE.txt) | 확인 (약 185k★, 10/28 push) |
| OpenAI Skills | https://github.com/openai/skills | Codex용 공식 스킬 카탈로그 | `skills/.curated/` 읽기, 필요한 폴더 복사 | 저장소 단위 SPDX 없음(LICENSE 직접 확인) | 확인 (약 28k★, 10/28 push) |
| openai/codex | https://github.com/openai/codex | Codex CLI 본체 | `docs/agents_md.md`, `docs/skills.md`, `docs/config.md` 읽기 | Apache-2.0 | 확인 (약 132k★, 10/30 push) |
| AGENTS.md 표준 | https://github.com/agentsmd/agents.md | 코딩 에이전트용 지침 파일 AGENTS.md 열린 형식(사이트 agents.md) | 형식 규칙만 읽기 | MIT | 확인 (약 25k★, 9/10 push; openai/agents.md는 이쪽으로 이전) |
| github/spec-kit | https://github.com/github/spec-kit | 스펙 주도 개발(SDD) 툴킷, 명세→계획→작업 템플릿 | `templates/`, `spec-driven.md` 읽기 | MIT | 확인 (약 144k★, 10/30 push) |
| BMAD-METHOD | https://github.com/bmad-code-org/BMAD-METHOD | 애자일 역할 에이전트로 요구·설계·구현을 진행하는 방법론 | 읽기만 | 라이선스 파일 확인 필요(API는 NOASSERTION) | 확인 (약 55k★) |
| ECC (구 everything-claude-code) | https://github.com/affaan-m/ECC | 스킬·메모리·보안 규칙을 묶은 하네스 최적화 모음 (Codex 등 겸용) | 읽기만 | MIT | 확인 (약 293k★) |
| oh-my-claudecode | https://github.com/Yeachan-Heo/oh-my-claudecode | Claude Code용 멀티에이전트 오케스트레이션 | 읽기만 | MIT | 확인 (약 40k★) |
| oh-my-openagent (구 oh-my-opencode) | https://github.com/code-yeongyu/oh-my-opencode | opencode용 에이전트 하네스(저장소명 변경됨) | 읽기만 | 라이선스 직접 확인 필요(NOASSERTION) | 확인 (약 70k★) |
| wshobson/agents | https://github.com/wshobson/agents | 여러 하네스용 에이전트·스킬 플러그인 마켓 | `plugins/` 읽기 | MIT | 확인 (약 42k★) |
| VoltAgent/awesome-codex-subagents | https://github.com/VoltAgent/awesome-codex-subagents | Codex 서브에이전트 130여 개 모음 | 필요한 항목만 참고 | MIT | 확인 (약 6.4k★) |
| VoltAgent/awesome-agent-skills | https://github.com/VoltAgent/awesome-agent-skills | 공식·커뮤니티 에이전트 스킬 큐레이션 목록 | 목록에서 링크 따라가기 | MIT | 확인 (약 36.6k★) |
| awesome-claude-code | https://github.com/hesreallyhim/awesome-claude-code | Claude Code 스킬·훅·명령 자료 큐레이션 | 목록만 읽기 | NOASSERTION(직접 확인) | 확인 (약 56.9k★) |
| awesome-claude-skills | https://github.com/ComposioHQ/awesome-claude-skills | Claude 스킬 큐레이션 목록 | 목록만 읽기 | 표기 없음 | 확인 (약 78k★, 9/18 이후 push 없음) |
| open-design | https://github.com/nexu-io/open-design | AI 디자인 에이전트 작업공간. 디자인시스템을 DESIGN.md와 skills로 기술 | `DESIGN.md`·skills 구조만 읽기 (저장소가 크다, 통째로 clone하지 않음) | Apache-2.0 | 확인 (약 105k★, 10/30 push) |
| awesome-cursorrules | https://github.com/PatrickJS/awesome-cursorrules | Cursor 규칙 파일 모음(지침 작성 예시 참고용) | 읽기만 | CC0-1.0 | 확인 (약 41k★, 5/30 이후 push 없음) |

## 2. 용도별 묶음과 볼 경로 (모두 저장소 목록 조회로 확인한 경로)
- 계획·요구 정리: superpowers `skills/brainstorming`, `skills/writing-plans`, `skills/executing-plans` / gstack `office-hours`, `plan-ceo-review`, `plan-eng-review`, `autoplan` / spec-kit `templates/spec-template.md`, `plan-template.md`, `tasks-template.md`, `spec-driven.md` / pstack `skills/architect`, `skills/interrogate`
- TDD·디버깅·검증: superpowers `skills/test-driven-development`, `systematic-debugging`, `verification-before-completion` / gstack `investigate`, `qa`, `qa-only` / pstack `skills/tdd`, `skills/principle-fix-root-causes`, `skills/principle-prove-it-works`
- 코드 리뷰·릴리스: superpowers `requesting-code-review`, `receiving-code-review`, `finishing-a-development-branch` / gstack `review`, `ship`, `land-and-deploy`, `cso`(보안) / openai/skills `gh-address-comments`, `gh-fix-ci`
- 병렬·서브에이전트: superpowers `dispatching-parallel-agents`, `subagent-driven-development`, `using-git-worktrees` / VoltAgent/awesome-codex-subagents / wshobson/agents `plugins/`
- 문서·지침 표준: openai/codex `docs/agents_md.md`, `docs/skills.md` / agentsmd/agents.md `README.md` / gstack 루트 `AGENTS.md`, `ETHOS.md` / superpowers 루트 `AGENTS.md` / spec-kit 루트 `AGENTS.md` / pstack `skills/technical-writing`
- 스킬 형식·작성법: anthropics/skills `spec/`, `template/`, `skills/skill-creator` / superpowers `skills/writing-skills` / gstack `write-skill` / openai/skills `skills/.curated/`
- 문서 파일 처리 스킬: anthropics/skills `skills/pdf`, `docx`, `pptx`, `xlsx`(출처가 있는 스킬별 LICENSE.txt를 따로 확인)
- 스킬 모음 목록(링크 허브): VoltAgent/awesome-agent-skills, awesome-claude-code

## 3. 확인 못 함 / 주의
- "pstack": 이름이 같은 저장소가 여럿이다. 원본은 cursor/plugins의 pstack(Poteto 작)이고 나머지는 미러·파생이다. `no-session/pstack`(gstack 포크, 약 150★)은 이름만 같은 별개 프로젝트다. poteto/pstack은 없음(404).
- cursor/plugins/pstack의 정확한 라이선스 종류: LICENSE 파일은 있으나 내용은 열어 보지 않았다.
- anthropics/skills, openai/skills의 저장소 단위 라이선스: API에 SPDX가 없다. 복사 전 파일을 직접 확인한다.
- BMAD-METHOD, oh-my-openagent, awesome-claude-code: API가 NOASSERTION으로 표기. 사용 조건은 LICENSE를 직접 읽는다.
- Aqua-123/pstack-for-codex의 라이선스·품질: 확인 안 함.
- 각 스킬의 실제 품질·Codex 호환 동작은 실행해 보지 않았다(목록·메타데이터만 확인).
- openai/agents.md 주소는 agentsmd/agents.md로 이전된 것으로 보임(API가 이전 이름을 새 이름으로 돌려줌).
