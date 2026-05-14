# flakewatch

`flakewatch` turns JUnit XML test results into a static, self-contained HTML
report for flaky and slow tests. It is designed for GitHub Actions: run your
normal tests, point `flakewatch` at the generated JUnit XML files, and upload
the HTML report as an artifact.

The default HTML workflow does not need SQLite, a cache, or restored artifacts.

## Quick start

Install the released Linux amd64 binary:

```sh
curl -fsSL -o /tmp/flakewatch.tar.gz \
  https://github.com/komagata/flakewatch/releases/download/v0.2.0/flakewatch-v0.2.0-linux-amd64.tar.gz
tar -xzf /tmp/flakewatch.tar.gz -C /tmp
sudo install /tmp/flakewatch /usr/local/bin/flakewatch
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
- slow tests: tests ranked by their maximum and average recorded duration
- sortable tables: click columns such as `Fail`, `Max seconds`, or `Avg seconds`
  to reorder the visible rows
- source links: file links from JUnit XML, with inferred Ruby test line links
  when the XML omits line numbers
- run summary: total tests, observations, and failures/errors

## GitHub Actions

Configure your test command to write JUnit XML, then generate and upload the
HTML report:

```yaml
- uses: actions/checkout@v4

- name: Run tests
  run: |
    bundle exec rspec \
      --format progress \
      --format RspecJunitFormatter \
      --out test-results/rspec.xml

- name: Install flakewatch
  run: |
    curl -fsSL -o /tmp/flakewatch.tar.gz \
      https://github.com/komagata/flakewatch/releases/download/v0.2.0/flakewatch-v0.2.0-linux-amd64.tar.gz
    tar -xzf /tmp/flakewatch.tar.gz -C /tmp
    sudo install /tmp/flakewatch /usr/local/bin/flakewatch

- name: Generate flakewatch report
  if: always()
  run: |
    flakewatch html \
      --junit "test-results/**/*.xml" \
      --output flakewatch.html \
      --source-base-url "https://github.com/${{ github.repository }}/blob/${{ github.sha }}" \
      --source-root "."

- name: Upload flakewatch report
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: flakewatch-report
    path: flakewatch.html
```

See `examples/github-actions.yml` for a complete workflow shape, including a
job summary note that tells readers where to find the uploaded report.

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

## Legacy SQLite Workflow

The older SQLite workflow is still available for local history experiments, but
it is not required for the recommended static HTML report:

```sh
flakewatch init --db .flakewatch/flakewatch.sqlite3
flakewatch ingest --db .flakewatch/flakewatch.sqlite3 --junit "test-results/**/*.xml"
flakewatch report --db .flakewatch/flakewatch.sqlite3 --format github-summary
flakewatch list --db .flakewatch/flakewatch.sqlite3
flakewatch history --db .flakewatch/flakewatch.sqlite3 --test pkg.Test.name
flakewatch serve --db .flakewatch/flakewatch.sqlite3 --host 127.0.0.1 --port 8787
```
