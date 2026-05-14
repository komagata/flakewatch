# Repository Guidelines

## Project Structure & Module Organization

`flakewatch` is a Tya CLI for ingesting JUnit XML into SQLite and reporting flaky tests. The entrypoint is `src/main.tya`, which imports the package modules under `src/flakewatch/`.

- `src/flakewatch/Cli.tya`: command parsing and CLI dispatch.
- `src/flakewatch/Database.tya`: SQLite connection, schema migration, and persistence helpers.
- `src/flakewatch/JUnit.tya`, `Ingest.tya`, `Score.tya`, `Report.tya`, `Server.tya`: parsing, ingestion, scoring, reporting, and local HTTP output.
- `tests/flakewatch_test.tya`: project tests.
- `tests/fixtures/junit/`: sample JUnit XML inputs.
- `assets/` and `examples/`: reserved for user-facing assets and runnable examples.

## Build, Test, and Development Commands

- `tya install`: install dependencies from `tya.toml` and `tya.lock`.
- `tya test`: run the full test suite, including dependency tests.
- `tya test tests/flakewatch_test.tya`: run only this project’s tests.
- `tya lint src tests`: run Tya linting on source and tests.
- `tya format -w src/flakewatch/Cli.tya`: format a touched file in place.
- `tya build src/main.tya -o flakewatch`: build a local executable.
- `tya run src/main.tya html --junit "tests/fixtures/junit/**/*.xml" --output tmp/flakewatch.html`: generate the static report without building.
- `tya run src/main.tya doctor`: check the local runtime.

Common local CLI flow:

```sh
tya run src/main.tya html \
  --junit "tests/fixtures/junit/**/*.xml" \
  --output tmp/flakewatch.html
```

## Coding Style & Naming Conventions

Use existing Tya style: two-space indentation, `CamelCase` classes, snake_case methods and local variables, and short module-level classes. Keep changes surgical and avoid introducing abstractions before duplication or complexity justifies them. Prefer parameterized SQL calls over string interpolation for database input.

Run `tya format -w` on files you edit. Lint may surface existing canonical `Self.` warnings outside your change; do not churn unrelated files just to silence pre-existing warnings.

## Testing Guidelines

Tests use Tya’s built-in `unittest` framework. Name test methods with the `test_...` prefix and keep fixtures under `tests/fixtures/`. Add or update focused tests when changing JUnit parsing, HTML reporting, ingestion idempotency, scoring, or CLI behavior. Use `tmp/` for generated reports and disposable SQLite databases.

## Commit & Pull Request Guidelines

Recent commits use short imperative English subjects, for example `Add Flakewatch CLI` and `Use released SQLite package dependency`. Keep commits focused on one behavior change. For this namespace, commit as `Masaki Komagata <komagata@gmail.com>`.

Pull requests should include a concise summary, test results such as `tya test`, linked issues when applicable, and screenshots or copied output for report/server UI changes.
