# 이슈 트래커: GitHub

이 저장소의 이슈와 spec은 GitHub Issues(`SNMac/SYKeyboard`)에 둔다. 모든 작업은 `gh` CLI로 한다.
저장소는 `git remote -v`에서 정해지며, clone 안에서 실행하면 `gh`가 알아서 찾는다.

## 이 저장소의 규칙

- **새 이슈는 사용자가 따로 명시적으로 허락한 뒤에만 만든다.** 여러 제안 중 하나로 끼워 넣은 승인은 허락으로 보지 않는다.
  허락이 없으면 관련된 기존 이슈 본문에 절을 추가하는 방식을 먼저 제안한다.
- 이슈 본문은 `.github/ISSUE_TEMPLATE/feature-issue-template.md`(📄 이슈 내용 / 📝 상세 내용 / ✅ 체크리스트)를 따른다.
  라벨은 `enhancement`, 담당자는 `SNMac`이 기본이다.
- 제목은 `[Type] 제목` 형식이다. 예: `[Refactor] 한영 통합 키보드 VC를 HangeulEnglishKeyboardCore 모듈의 Core VC로 추출`, `[Feat] ...`.
- 이슈·댓글 본문은 덮어쓰지 않는다. 사용자가 웹에서 넣은 스크린샷 등이 있을 수 있으므로 필요한 절만 고친다.
- Linear는 GitHub Issue에서 파생된 작업 추적·상태 관리용이다. Linear 이슈는 사용자가 명시적으로 요청할 때만 만든다.
- Crashlytics 크래시 이슈는 분류 봇이 만든다. 처리 방식은 `CLAUDE.md`의 `이슈 관리` > `Crashlytics 크래시 이슈`를 따른다.
- 마크다운 본문에서 범위를 물결표로 쓸 때는 `\~`로 이스케이프한다.

## 명령

- **이슈 만들기**: `gh issue create --title "..." --body "..." --label enhancement --assignee SNMac`. 여러 줄 본문은 heredoc을 쓴다.
- **이슈 읽기**: `gh issue view <번호> --comments`. 라벨도 함께 확인한다.
- **이슈 목록**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'`에 `--label`, `--state` 필터를 붙인다.
- **댓글 달기**: `gh issue comment <번호> --body "..."`
- **라벨 붙이기·떼기**: `gh issue edit <번호> --add-label "..."` / `--remove-label "..."`
- **닫기**: `gh issue close <번호> --comment "..."`

## Pull request를 요청 창구로 쓰는지

**PRs as a request surface: no.** _(외부 PR을 기능 요청으로 다루는 저장소라면 `yes`로 바꾼다. `/triage`가 이 값을 읽는다.)_

`yes`일 때 PR은 이슈와 같은 라벨·상태를 거치며 `gh pr` 명령을 쓴다.

- **PR 읽기**: `gh pr view <번호> --comments`, diff는 `gh pr diff <번호>`.
- **triage할 외부 PR 목록**: `gh pr list --state open --json number,title,body,labels,author,authorAssociation,comments`에서 `authorAssociation`이 `CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR`, `NONE`인 것만 남긴다(`OWNER`/`MEMBER`/`COLLABORATOR` 제외).
- **댓글·라벨·닫기**: `gh pr comment`, `gh pr edit --add-label`/`--remove-label`, `gh pr close`.

GitHub는 이슈와 PR이 번호 공간을 공유하므로 `#42`만으로는 어느 쪽인지 모른다. `gh pr view 42`로 먼저 확인하고 실패하면 `gh issue view 42`를 쓴다.

## 스킬이 "이슈 트래커에 게시하라"고 할 때

위 규칙에 따라 사용자 허락을 받은 뒤 GitHub 이슈를 만든다.

## 스킬이 "관련 티켓을 가져오라"고 할 때

`gh issue view <번호> --comments`를 실행한다.

## Wayfinding 작업

`/wayfinder`가 쓴다. **map**은 이슈 하나이고 **child** 이슈가 티켓이다. map·child 이슈를 새로 만드는 것도 위의 허락 규칙을 따른다.

- **Map**: `wayfinder:map` 라벨이 붙은 이슈 하나. 본문에 Notes / Decisions-so-far / Fog를 둔다. `gh issue create --label wayfinder:map`.
- **Child 티켓**: map에 GitHub sub-issue로 연결한 이슈(sub-issues 엔드포인트에 `gh api`). sub-issue를 쓸 수 없으면 map 본문 task list에 child를 넣고 child 본문 맨 위에 `Part of #<map>`을 적는다. 라벨은 `wayfinder:<type>`(`research`/`prototype`/`grilling`/`task`). 맡으면 작업하는 개발자를 assignee로 지정한다.
- **Blocking**: GitHub **native issue dependencies**를 기준으로 한다. `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`로 추가한다. `<blocker-db-id>`는 `#번호`나 `node_id`가 아니라 숫자 **database id**다(`gh api repos/<owner>/<repo>/issues/<n> --jq .id`). `issue_dependencies_summary.blocked_by`가 열린 blocker 수다. dependencies를 쓸 수 없으면 child 본문 맨 위에 `Blocked by: #<n>, #<n>` 줄을 둔다. blocker가 모두 닫히면 unblocked다.
- **Frontier 조회**: map의 열린 child(`gh issue list --state open`, map의 sub-issue/task list로 한정)에서 열린 blocker가 있거나(`issue_dependencies_summary.blocked_by > 0` 또는 `Blocked by` 줄의 열린 이슈) assignee가 있는 것을 뺀다. map 순서상 첫 번째가 선택된다.
- **Claim**: `gh issue edit <n> --add-assignee @me`. 세션의 첫 쓰기 작업이다.
- **Resolve**: `gh issue comment <n> --body "<답>"` → `gh issue close <n>` → map의 Decisions-so-far에 요지와 링크를 덧붙인다.
