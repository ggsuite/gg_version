# Change Log

## 2.0.1

## 2.0.0

- Fix: Version can now be read from cider formatted CHANGELOG.md
- Breaking chang: PrepareNextVersion will not update CHANGELOG.md anymore.
  CHANGELOG.md will be updated by cider in the future. Cider is reading
  the version from pubspec.yaml.

## 1.3.1

- Fix: Success message was logged twice

## 1.3.0

- Add `nextVersion()` and `calculateNextVersion()`

## 1.2.0

- Add PrepareNextVersion, PublishedVersion, IsVersionPrepared

## 1.1.1

- Update dependencies

## 1.1.0

- Add `IncreaseBuild` command

## 1.0.12

- Updage GgConsoleColors

## 1.0.11

- Add GgLog

## 1.0.10

- Add ignoreVersion param to ignore one of the versions when executing
  is_versionsed or consistent_version

## 1.0.9

- Add mocktail mocks

## 1.0.8

- Rework directory handling

## 1.0.7

- Rename `is_consistent` -> `is_versioned`
- Shorten descriptions

## 1.0.6

- Better command line output

## 1.0.2

- Update dependencies

## 1.0.1

- Rename `Get` into `Versioned`

## 1.0.0

- Initial version.
