# Feature: CircleCI-compatible branch-aware test history

## Goal

Make Flakewatch a practical replacement for CircleCI Test Insights by collecting
trusted test results from every branch, retaining a 14-day history, detecting
flakes only when the same test both passes and fails on the same commit, and
keeping current-run failures separate from historical failure statistics.

## Context

The JSONL format already stores `branch`, `sha`, `event`, and every JUnit test
status. However, the GitHub Action's default `history-write: auto` skips all
pull request runs, its checkout step discards nearly all older JSONL files, and
the report combines every historical observation without filtering or grouping
by commit. This means normal changes in test behavior across commits can be
reported as flakes.

CircleCI defines a flaky test as one that both passes and fails on the same
commit within a 14-day window. Its test views also allow data from all branches
or a selected branch.

## Behavior

- Keep exporting every observed JUnit test, including `passed`, `failed`,
  `error`, and `skipped`; do not store failures alone.
- `history-write: auto` writes history for:
  - push runs on every branch;
  - pull requests whose head repository is the same repository.
- `history-write: auto` does not write history for fork pull requests. Such
  runs still read persistent history and generate a report, and emit a GitHub
  Actions notice explaining why the write was skipped.
- For pull requests, persist the source branch name from `GITHUB_HEAD_REF`;
  otherwise use `GITHUB_REF_NAME`.
- Retain JSONL run files for 14 calendar days, including the current day.
  Remove only run files in the date-based `history/YYYY/MM/DD/` layout that are
  older than the retention window. Do not use checkout time or lexicographic
  "keep latest file" pruning.
- Keep one file per GitHub `run_id` and `run_attempt`, so rerunning the same
  attempt replaces its file rather than creating duplicate observations.
- The default analysis scope includes all branches.
- Add an `analysis-branch` GitHub Action input and matching
  `--analysis-branch` CLI option. It accepts `*` for all branches or one exact
  branch name. The default is `*`.
- Filter historical observations to the selected analysis scope before
  calculating historical sections. Records with an empty branch remain
  readable when the scope is `*`, but do not match an exact branch.
- Enrich current JUnit observations with the current `sha`, `branch`, run, and
  job metadata while rendering, as well as while exporting JSONL.
- A test is flaky only when at least one pass and at least one failure or error
  exist for that test with the same non-empty commit SHA in the retained,
  branch-filtered observations. Pass/fail variation across different commits
  must not produce a flake.
- Treat `skipped` as neither a pass nor a failure for flake detection.
- Rank flaky tests using the existing transition/failure scoring within
  qualifying same-commit observations. A test may qualify from any commit in
  the selected 14-day scope.
- `Failing Tests` shows only failures and errors from the current JUnit input.
  Historical failures from other runs or branches must not appear there.
- Add `Most Failed Tests` for retained, branch-filtered history, ranked by
  failure/error count, so historical reliability remains visible separately.
- Preserve the existing healed and slow-test reporting, but calculate
  historical classifications only from the retained, branch-filtered history.
- Document collection trust rules, the 14-day window, all-branch default,
  branch filtering, all-status storage, and the distinction between current
  failures and historical failures.

## Scope

- `action.yml`: trusted-run history writes, PR source branch metadata,
  retention pruning, and the `analysis-branch` input.
- `src/flakewatch/application.tya`: CLI option and normalized GitHub metadata.
- `src/flakewatch/history.tya`: any record/filter helpers needed by reporting.
- `src/flakewatch/report.tya` and report view/template files: branch filtering,
  same-commit flake detection, and separate failure sections.
- `tests/circleci_history_test.tya` and focused fixtures: branch, commit,
  status, and report-section coverage.
- `README.md` and `examples/github-actions.yml`: migration-oriented usage and
  configuration documentation.

## Out of Scope

- Importing existing CircleCI history through its API.
- Reproducing CircleCI's UI exactly.
- Supporting arbitrary boolean branch expressions or glob patterns beyond `*`
  and one exact branch name.
- Writing history from fork pull requests or using `pull_request_target`.
- Changing the test identity beyond the existing class/suite plus test name.
- Adding a database, remote service, or non-Git history backend.
- Configurable retention periods in this feature.

## Acceptance Criteria

- Default GitHub Action behavior records push results from non-default branches
  and same-repository pull requests.
- Fork pull requests never attempt to commit or push history in `auto` mode and
  receive an explanatory notice.
- A pull request record contains its source branch rather than a merge ref.
- History keeps all run files from the latest 14 calendar days and removes
  older date-based files.
- Exported JSONL continues to contain every test status and its branch and SHA.
- With the default `analysis-branch: "*"`, observations from all branches are
  eligible for analysis.
- Selecting `analysis-branch: main` excludes records from every other branch.
- Pass and failure on the same non-empty SHA produce a flaky test.
- Pass and failure on different SHAs do not produce a flaky test.
- Skipped plus failed on the same SHA does not produce a flaky test.
- `Failing Tests` contains only current-run failures.
- `Most Failed Tests` contains historical failures from the selected scope.
- Existing report generation, history-only reporting, source links, artifact
  upload, job summary, and PR-description behavior continue to work.
- Documentation explains the migration behavior and security limitation.

## Verification

```sh
TYA_SAFE_TIMEOUT=120 ./scripts/tya-tmux test tests/flakewatch_test.tya
TYA_SAFE_TIMEOUT=120 ./scripts/tya-tmux test tests/circleci_history_test.tya
TYA_SAFE_TIMEOUT=120 ./scripts/tya-tmux lint src tests
TYA_SAFE_TIMEOUT=120 ./scripts/tya-tmux build src/main.tya -o tmp/flakewatch
ruby -e 'require "yaml"; YAML.safe_load(File.read("action.yml"), aliases: true)'
actionlint .github/workflows/*.yml examples/*.yml
```
