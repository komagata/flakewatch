# flakewatch

`flakewatch` ingests JUnit XML test results into a local SQLite database and
reports likely flaky tests. It is designed for GitHub Actions workflows that
want historical flake visibility without sending test data to a hosted service.

## Commands

```sh
flakewatch init --db .flakewatch/flakewatch.sqlite3
flakewatch ingest --db .flakewatch/flakewatch.sqlite3 --junit "test-results/**/*.xml"
flakewatch report --db .flakewatch/flakewatch.sqlite3 --format github-summary
flakewatch list --db .flakewatch/flakewatch.sqlite3
flakewatch history --db .flakewatch/flakewatch.sqlite3 --test pkg.Test.name
flakewatch serve --db .flakewatch/flakewatch.sqlite3 --host 127.0.0.1 --port 8787
flakewatch doctor
```

`ingest` reads GitHub Actions metadata from environment variables when explicit
flags are omitted. The database is local SQLite and can be stored as an
artifact or cache between workflow runs.

## GitHub Actions

```yaml
- name: Restore flakewatch database
  uses: actions/download-artifact@v4
  continue-on-error: true
  with:
    name: flakewatch-db
    path: .flakewatch

- name: Initialize flakewatch database
  run: flakewatch init --db .flakewatch/flakewatch.sqlite3

- name: Ingest JUnit
  run: |
    flakewatch ingest \
      --db .flakewatch/flakewatch.sqlite3 \
      --junit "test-results/**/*.xml"

- name: Flake summary
  run: |
    flakewatch report \
      --db .flakewatch/flakewatch.sqlite3 \
      --format github-summary >> "$GITHUB_STEP_SUMMARY"

- name: Save flakewatch database
  uses: actions/upload-artifact@v4
  with:
    name: flakewatch-db
    path: .flakewatch/flakewatch.sqlite3
```

`actions/cache` can be used instead of artifacts when cache semantics are a
better fit for the project.
