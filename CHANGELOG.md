# Changelog

## [Unreleased]

### Changed

- Rework changelog + repository URL in pubspec.yaml
- 'Github Actions Pipeline'
- 'Github Actions Pipeline: Add SDK file containing flutter into .github/workflows to make github installing flutter and not dart SDK'

### Removed

- pubspec.lock
- Add pubspec.lock to .gitignore
- test/sample\_package/pubspec.lock

## 2.0.2 - 2024-01-01

- `IsVersionPrepared`: `treatUnpublishedAsOk` can be set using constructor

## 2.0.1 - 2024-01-01

- \[Unreleased\] section at the beginning of CHANGELOG.md will not affect `FromChangeLog`
- Add option `treatUnpublishedAsOk` to `IsVersionPrepared.get()`

## 2.0.0 - 2024-01-01

- Fix: Version can now be read from cider formatted CHANGELOG.md
- Breaking chang: PrepareNextVersion will not update CHANGELOG.md anymore.
CHANGELOG.md will be updated by cider in the future. Cider is reading
the version from pubspec.yaml.

## 1.3.1 - 2024-01-01

- Fix: Success message was logged twice

## 1.3.0 - 2024-01-01

- Add `nextVersion()` and `calculateNextVersion()`

## 1.2.0 - 2024-01-01

- Add PrepareNextVersion, PublishedVersion, IsVersionPrepared

## 1.1.1 - 2024-01-01

- Update dependencies

## 1.1.0 - 2024-01-01

- Add `IncreaseBuild` command

## 1.0.12 - 2024-01-01

- Updage GgConsoleColors

## 1.0.11 - 2024-01-01

- Add GgLog

## 1.0.10 - 2024-01-01

- Add ignoreVersion param to ignore one of the versions when executing
is\_versionsed or consistent\_version

## 1.0.9 - 2024-01-01

- Add mocktail mocks

## 1.0.8 - 2024-01-01

- Rework directory handling

## 1.0.7 - 2024-01-01

- Rename `is_consistent` -> `is_versioned`
- Shorten descriptions

## 1.0.6 - 2024-01-01

- Better command line output

## 1.0.2 - 2024-01-01

- Update dependencies

## 1.0.1 - 2024-01-01

- Rename `Get` into `Versioned`

## 1.0.0 - 2024-01-01

- Initial version.

[Unreleased]: https://github.com/inlavigo/gg_version/compare/2.0.2...HEAD
