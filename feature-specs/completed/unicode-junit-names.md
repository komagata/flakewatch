# Feature: Unicode JUnit Test Names

## Goal
Make Flakewatch generate reports from JUnit XML files whose testcase names contain Unicode text, relying on Tya's fixed XML parser instead of adding Flakewatch-specific text or bytes workarounds.

## Context
`komagata/flakewatch#5` reproduces with a Bootcamp JUnit dataset containing Japanese testcase names. The current failure is rooted in Tya's XML parser bug `komagata/tya#33`, where non-ASCII XML attribute values raise `+ expects numbers, strings, or bytes of the same kind`. Tya will be fixed first through the String/Bytes semantics and character-indexed parser specs. Flakewatch should then depend on that corrected Tya behavior and add focused regression coverage for JUnit Unicode names.

Relevant files include:

- `tya.toml`
- `tya.lock`
- `src/flakewatch/j_unit.tya`
- `src/flakewatch/report.tya`
- `tests/flakewatch_test.tya`
- `tests/fixtures/junit/`
- `README.md`

The large reproduction dataset can be restored from the gist linked in `komagata/flakewatch#5`. It should be used for manual verification, not committed as a fixture.

## Behavior
- Flakewatch accepts JUnit XML testcase `name` attributes containing Japanese or other non-ASCII Unicode text.
- Flakewatch preserves Unicode testcase names in parsed JUnit items.
- HTML reports include Unicode testcase names after template escaping.
- Unicode testcase names can participate in aggregation keys without raising string/bytes errors.
- Source-link inference may attempt to match Unicode test names in source files, but missing source matches must not block report generation.
- Flakewatch does not add a local workaround for Tya's XML parser bug. It should use a Tya version where Unicode XML attributes parse correctly.
- ASCII JUnit XML behavior remains unchanged.

## Scope
- Update `tya.toml` and `tya.lock` to a Tya release that includes the XML Unicode fix.
- Add a small Unicode JUnit fixture under `tests/fixtures/junit/`.
- Add focused tests in `tests/flakewatch_test.tya` proving Unicode testcase names are parsed and rendered.
- Run the large Bootcamp reproduction dataset from `komagata/flakewatch#5` as a manual verification command.
- Update README only if the supported Tya version or troubleshooting notes need to be clarified.

## Out of Scope
- Fixing Tya's String/Bytes semantics or XML parser. Those are Tya feature specs.
- Adding Flakewatch-specific byte decoding, lossy Unicode cleanup, or defensive text normalization for XML parser output.
- Committing the large Bootcamp JUnit reproduction dataset.
- Changing Flakewatch's flaky/slow/healed scoring.
- Changing report design or table layout.
- Adding full JUnit schema support beyond the Unicode testcase-name regression.

## Acceptance Criteria
- `JUnit().parse_file(...)` returns a testcase item whose `name` is exactly a Japanese Unicode string from the fixture.
- `Report().render(...)` includes the Japanese testcase name in the generated HTML.
- The Unicode fixture test fails with the current broken Tya XML parser and passes with the fixed Tya release.
- Running Flakewatch against the restored Bootcamp dataset from `komagata/flakewatch#5` writes `tmp/bootcamp-large-junit.html` without `+ expects numbers, strings, or bytes of the same kind`.
- Existing Flakewatch tests continue to pass.
- No Flakewatch code is added solely to convert XML parser byte fragments into strings.

## Verification
```sh
tya install
tya test tests/flakewatch_test.tya
tya run src/main.tya \
  --junit='tmp/reproductions/bootcamp-junit-26864749418/**/*.xml' \
  --output=tmp/bootcamp-large-junit.html \
  --source-root=/Users/komagata/Projects/fjordllc/bootcamp
tya lint src tests
```
