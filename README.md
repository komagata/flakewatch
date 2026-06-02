# flakewatch

`flakewatch` turns JUnit XML test results into a static, self-contained HTML
report for flaky and slow tests. It is designed for GitHub Actions: run your
normal tests, point `flakewatch` at the generated JUnit XML files, and it will
generate, upload, and link the HTML report.

The default HTML workflow does not need a cache or restored artifacts.

## Local CI

Install the released Linux amd64 binary:

```sh
curl -fsSL https://raw.githubusercontent.com/komagata/flakewatch/main/install.sh | sh
```

For local CI or a self-managed runner, store both the HTML report and history
files on the local filesystem:

```sh
bundle exec rails test

mkdir -p tmp/flakewatch/history

flakewatch \
  --junit="test/reports/**/*.xml" \
  --history="tmp/flakewatch/history/**/*.jsonl" \
  --history-output="tmp/flakewatch/history/run-$(date -u +%Y%m%d%H%M%S).jsonl" \
  --output="tmp/flakewatch/report.html"
```

Open `tmp/flakewatch/report.html` in a browser to inspect the report.

The report contains:

- flaky tests: tests that appear with both passing and failing/error outcomes
  across the provided JUnit files
- healed candidates: tests that had past pass/fail variation but whose 10 most
  recent observations are all passing
- failing tests: tests ranked by total failure and error observations
- slow tests: tests ranked by their maximum and average recorded duration
- sortable tables: click columns such as `Failures`, `Max seconds`, or
  `Avg seconds` to reorder the visible rows
- source links: file links from JUnit XML, with inferred Ruby test line links
  when the XML omits line numbers
- run summary: total tests, observations, and failures/errors

## GitHub Actions

The most common path is GitHub Actions with Rails, Minitest, and
[`minitest-ci`](https://rubygems.org/gems/minitest-ci). Add the test reporter:

```ruby
# Gemfile
group :test do
  gem "minitest-ci"
end
```

Require it from the Rails test helper:

```ruby
# test/test_helper.rb
require "minitest/ci"
```

Then run the Rails tests and pass the generated JUnit XML files to Flakewatch:

```yaml
name: CI

on:
  pull_request:
  push:

permissions:
  contents: read
  pull-requests: write

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      - name: Run tests
        run: bundle exec rails test

      - name: Generate flakewatch report
        if: always()
        uses: komagata/flakewatch@v0.6.18
```

By default, the action:

- generates `flakewatch.html`
- uploads it as an artifact containing `flakewatch.html`
- adds a download link to the job summary
- adds or updates a `Flakewatch Report` block with a linked banner image in the
  pull request description

`pull-requests: write` is required only for updating the pull request
description. If the token cannot update the pull request, the action keeps the
CI job green and the job summary still links to the artifact.

See `examples/github-actions.yml` for a complete workflow shape.

For other test stacks, see the GitHub Wiki:

- [Rails + RSpec](https://github.com/komagata/flakewatch/wiki/Rails-and-RSpec)
- [Django + pytest](https://github.com/komagata/flakewatch/wiki/Django-and-pytest)

### Matrix Test Jobs

When tests run in a matrix, upload JUnit XML from each test job and run
Flakewatch once in a final fan-in job:

```yaml
jobs:
  test:
    strategy:
      fail-fast: false
      matrix:
        shard: [0, 1, 2, 3]
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Run tests
        run: |
          bundle exec rails test \
            --junit \
            --junit-filename "test-results/junit-${{ matrix.shard }}.xml"

      - uses: actions/upload-artifact@v7
        if: always()
        with:
          name: junit-${{ matrix.shard }}
          path: test-results/**/*.xml

  flakewatch:
    needs: test
    if: always()
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: komagata/flakewatch@v0.6.18
        with:
          junit-artifact-pattern: junit-*
```

When `junit-artifact-pattern` is set, Flakewatch downloads matching artifacts
into `test-results` and reads `test-results/**/*.xml`. It reads XML files in
stable path order. If JUnit XML contains `testsuite timestamp` values, the
report uses timestamp plus path order for observation ordering.

### Persistent History

By default, Flakewatch analyzes only the JUnit XML files from the current
workflow run. To detect flaky tests across runs, store compact JSONL history in
a dedicated Git branch:

```yaml
permissions:
  contents: write
  pull-requests: write

- name: Generate flakewatch report
  if: always()
  uses: komagata/flakewatch@v0.6.18
  with:
    history-branch: flakewatch-data
```

When `history-branch` is set, the action reads
`history/**/*.jsonl` from that branch before generating the HTML report. It
then writes the current run to a file such as:

```text
history/2026/05/18/run-123456789-attempt-1.jsonl
```

The default `history-write: auto` writes history only outside
`pull_request` events. This lets trusted branch runs update the history while
pull request runs can still read it when permissions allow.

If you want pull request runs to write history too, opt in explicitly:

```yaml
permissions:
  contents: write
  pull-requests: write

- name: Generate flakewatch report
  if: always()
  uses: komagata/flakewatch@v0.6.18
  with:
    history-branch: flakewatch-data
    history-write: true
```

With the default `history-write: auto`, pull request runs that set
`history-branch` emit a GitHub Actions warning so the skipped history write is
visible in the job log.

### Action Inputs

| Input | Default | Description |
|---|---|---|
| `junit` | `test/reports/**/*.xml` | JUnit XML glob. The default matches `minitest-ci` output. |
| `output` | `flakewatch.html` | HTML report output path. |
| `source-base-url` | current GitHub commit URL | Base URL for source links. |
| `source-root` | `.` | Local source root used to infer Ruby test line links. |
| `version` | `v0.6.18` | Flakewatch release version to install. |
| `upload-artifact` | `true` | Upload the generated HTML report as a GitHub Actions artifact. |
| `artifact-name` | `flakewatch.html` | GitHub Actions artifact name for the generated HTML report. |
| `junit-artifact-pattern` | empty | JUnit XML artifact name pattern to download, for example `junit-*`. When set, Flakewatch reads `download-artifact-path/**/*.xml`. |
| `download-artifacts` | `false` | Download JUnit XML artifacts before generating the report. Use this in a fan-in job after matrix test jobs upload XML artifacts. |
| `download-artifact-pattern` | empty | Lower-level artifact name pattern used with `download-artifacts: true`. Prefer `junit-artifact-pattern` for JUnit fan-in. |
| `download-artifact-path` | `test-results` | Destination directory for downloaded JUnit XML artifacts. |
| `merge-artifacts` | `true` | Merge downloaded artifacts into `download-artifact-path`. |
| `update-pr-description` | `true` | Add or update a Flakewatch report link in the pull request description. |
| `add-job-summary` | `true` | Add a Flakewatch report link to the GitHub Actions job summary. |
| `history-branch` | empty | Git branch used to persist JSONL test history. |
| `history-write` | `auto` | Write JSONL history to `history-branch`. `auto` writes outside pull request events. |

## Command

```sh
flakewatch \
  --junit="test-results/**/*.xml" \
  --history="flakewatch-history/history/**/*.jsonl" \
  --history-output="flakewatch-history/history/run.jsonl" \
  --output=flakewatch.html \
  --source-base-url="https://github.com/OWNER/REPO/blob/COMMIT_SHA" \
  --source-root="."
```

`--source-base-url` enables GitHub links in the report. `--source-root` points
to the checked-out source tree and is used to infer Ruby test method line links
when JUnit XML only includes a file path.

Observation order is based on JUnit `testsuite timestamp` when present. If the
XML has no timestamp, Flakewatch falls back to the sorted file path order.
