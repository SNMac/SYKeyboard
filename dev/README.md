# Development Workspace

이 디렉터리는 장기 작업의 계획, 결정, 체크리스트를 보관하는 작업 공간이다. 목적은 Codex 세션이 길어지거나 컨텍스트가 줄어들어도 진행 중인 작업의 맥락을 잃지 않는 것이다.

## 언제 사용하나

- 한 번에 끝나지 않는 기능, 리팩터링, 버그 수정
- 한글 입력/삭제 로직처럼 회귀 위험이 큰 작업
- 여러 모듈(`SYKeyboard`, `Keyboards`, `Modules`, `SYKeyboardTests`)을 함께 건드리는 작업
- 사용자와 설계/범위/검증 기준을 맞춰야 하는 작업

작은 오타 수정, 단일 문서 수정, 명확한 한 줄 변경에는 만들지 않아도 된다.

## 디렉터리 구조

새 작업은 아래 구조로 만든다.

```text
dev/active/<task-name>/
├── <task-name>-plan.md
├── <task-name>-context.md
├── <task-name>-tasks.md
└── superpowers/
    ├── specs/
    │   └── YYYY-MM-DD-<task-name>-design.md
    └── plans/
        └── YYYY-MM-DD-<task-name>.md
```

작업이 완료되면 필요에 따라 `dev/archive/<task-name>/`로 옮긴다.

`superpowers/`는 Superpowers 스킬을 사용할 때만 만든다. Superpowers가 기본 경로로 제시하는 `docs/superpowers/`는 사용하지 않고, 위 작업 디렉터리 아래에서 `specs/`와 `plans/` 구조를 유지한다.

## 파일 역할

- `*-plan.md`: 목표, 현재 상태, 접근 방식, 위험, 검증 방법을 정리한다.
- `*-context.md`: 관련 파일, 주요 결정, 열어본 문서, 주의할 도메인 규칙을 기록한다.
- `*-tasks.md`: 실제 실행 체크리스트다. 각 항목은 확인 가능한 완료 기준을 가져야 한다.
- `superpowers/specs/`: Superpowers `brainstorming`이 생성하는 상세 설계 문서를 보관한다.
- `superpowers/plans/`: Superpowers `writing-plans`가 생성하는 상세 구현 계획을 보관한다.

## 작성 규칙

- 모든 파일 상단에 `Last Updated: YYYY-MM-DD`를 둔다.
- 경로는 저장소 루트 기준 상대 경로로 쓴다.
- 추정은 추정이라고 표시하고, 확인한 사실과 섞지 않는다.
- 테스트/빌드 명령은 실제로 실행할 명령 그대로 적는다.
- 완료된 항목은 바로 체크한다. 마지막에 한꺼번에 맞추지 않는다.
- 작업 중 새로 알게 된 제약은 `*-context.md`에 기록한다.
- Superpowers 문서는 스킬이 요구하는 형식과 상세 수준을 유지하며 일반 작업 문서 템플릿에 맞춰 축약하지 않는다.

## 빠른 시작

```sh
mkdir -p dev/active/<task-name>
cp dev/templates/task-plan-template.md dev/active/<task-name>/<task-name>-plan.md
cp dev/templates/task-context-template.md dev/active/<task-name>/<task-name>-context.md
cp dev/templates/task-tasks-template.md dev/active/<task-name>/<task-name>-tasks.md
```

`<task-name>`은 소문자 영문, 숫자, 하이픈으로 작성한다. 예: `hangeul-delete-regression`, `keyboard-height-settings`.

Superpowers를 사용하는 경우 필요한 디렉터리를 추가한다.

```sh
mkdir -p dev/active/<task-name>/superpowers/specs
mkdir -p dev/active/<task-name>/superpowers/plans
```
