# flakewatch

`flakewatch` turns JUnit XML test results into a static HTML report for flaky
and slow tests. It is designed to be easy to drop into GitHub Actions: point it
at your JUnit files, upload the generated HTML, and inspect the report in the
workflow artifacts.

## Quick start

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
- source links: file links from JUnit XML, with inferred Ruby test line links
  when the XML omits line numbers
- run summary: total tests, observations, and failures/errors

## GitHub Actions

Add one report step after your test command, then upload the HTML artifact:

```yaml
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

No database, cache, or artifact restore step is required for the HTML workflow.
See `examples/github-actions.yml` for a complete workflow shape, including a
job summary note that tells readers where to find the uploaded report.

## Commands

```sh
flakewatch html --junit "test-results/**/*.xml" --output flakewatch.html
flakewatch doctor
```

The older SQLite workflow is still available for local history experiments:

```sh
flakewatch init --db .flakewatch/flakewatch.sqlite3
flakewatch ingest --db .flakewatch/flakewatch.sqlite3 --junit "test-results/**/*.xml"
flakewatch report --db .flakewatch/flakewatch.sqlite3 --format github-summary
flakewatch list --db .flakewatch/flakewatch.sqlite3
flakewatch history --db .flakewatch/flakewatch.sqlite3 --test pkg.Test.name
flakewatch serve --db .flakewatch/flakewatch.sqlite3 --host 127.0.0.1 --port 8787
```
