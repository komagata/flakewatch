# flakewatch

`flakewatch` turns JUnit XML test results into a static, self-contained HTML
report for flaky and slow tests. It is designed for GitHub Actions: run your
normal tests, point `flakewatch` at the generated JUnit XML files, and upload
the HTML report as an artifact.

The default HTML workflow does not need SQLite, a cache, or restored artifacts.

## Quick start

Install the released Linux amd64 binary:

```sh
curl -fsSL https://raw.githubusercontent.com/komagata/flakewatch/main/install.sh | sh
```

Generate a report from JUnit XML:

```sh
flakewatch html \
  --junit "test-results/**/*.xml" \
  --output flakewatch.html \
  --source-base-url "https://github.com/OWNER/REPO/blob/COMMIT_SHA" \
  --source-root "."
```

The report contains:

- flaky tests: tests that appear with both passing and failing/error outcomes
  across the provided JUnit files
- healed candidates: tests that had past pass/fail variation but whose 10 most
  recent observations are all passing
- slow tests: tests ranked by their maximum and average recorded duration
- sortable tables: click columns such as `Fail`, `Max seconds`, or `Avg seconds`
  to reorder the visible rows
- source links: file links from JUnit XML, with inferred Ruby test line links
  when the XML omits line numbers
- run summary: total tests, observations, and failures/errors

## GitHub Actions

Configure your test command to write JUnit XML, then generate and upload the
HTML report with the Flakewatch action:

```yaml
- uses: actions/checkout@v4

- name: Run tests
  run: |
    bundle exec rspec \
      --format progress \
      --format RspecJunitFormatter \
      --out test-results/rspec.xml

- name: Generate flakewatch report
  if: always()
  uses: komagata/flakewatch@v0.4.0
  with:
    junit: "test-results/**/*.xml"
    output: flakewatch.html

- name: Upload flakewatch report
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: flakewatch-report
    path: flakewatch.html
```

See `examples/github-actions.yml` for a complete workflow shape, including a
job summary note that tells readers where to find the uploaded report.

### Action Inputs

| Input | Default | Description |
|---|---|---|
| `junit` | `test-results/**/*.xml` | JUnit XML glob. Use `**/*.xml` for recursive matching. |
| `output` | `flakewatch.html` | HTML report output path. |
| `source-base-url` | current GitHub commit URL | Base URL for source links. |
| `source-root` | `.` | Local source root used to infer Ruby test line links. |
| `version` | `v0.4.0` | Flakewatch release version to install. |

## Commands

```sh
flakewatch html \
  --junit "test-results/**/*.xml" \
  --output flakewatch.html \
  --source-base-url "https://github.com/OWNER/REPO/blob/COMMIT_SHA" \
  --source-root "."

flakewatch doctor
```

`--source-base-url` enables GitHub links in the report. `--source-root` points
to the checked-out source tree and is used to infer Ruby test method line links
when JUnit XML only includes a file path.

Observation order is based on JUnit `testsuite timestamp` when present. If the
XML has no timestamp, Flakewatch falls back to the sorted file path order.
