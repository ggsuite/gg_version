# Changelog

## Unreleased

### Changed

- Rework copyright headers

### Fixed

- Cleanup copy right headers. Update to dart 3.13. Auto fixes.
- Cleanup copy right headers. Update to dart 3.13. Auto fixes. Setup quick-check pipeline.

## 5.2.2 - 2026-08-11

### Changed

- Provide gg via npm
- Fix shell changes

## 5.2.1 - 2026-08-10

### Fixed

- Various fixes

## 5.2.0 - 2026-08-09

### Changed

- Improve commit behavior

## 5.1.0 - 2026-08-09

## 5.0.0 - 2026-08-08

### Changed

- Allow to pass custom options to exec of dir commands.

## 4.6.1 - 2026-08-04

### Changed

- Merge origin/main and tighten dependency constraints (dart pub upgrade --tighten)

## 4.6.0 - 2026-08-04

### Changed

- Rename .master in .ocean

## 4.5.2 - 2026-08-04

### Changed

- Finetune command line output

## 4.5.1 - 2026-07-30

### Added

- Add package version number code to each package

## 4.5.0 - 2026-07-29

### Changed

- Support projects without manifest: ProjectType.none, checks skipped, version tracked as git tag only
- gg_multi: changed references to git
- gg_multi: changed references to git

## 4.4.1 - 2026-07-22

### Changed

- gg_multi: changed references to git

## 4.4.0 - 2026-07-20

### Added

- Add rc prerelease channel to gg do publish (channel field/flag, X.Y.Z-rc.N computation, npm --tag rc, single + multi repo)
- Address review: wrap registry version-parse errors as RegistryException, clarify spent-version rc message, lock cider rc changelog format

### Changed

- gg_multi: changed references to git

## 4.3.0 - 2026-07-01

### Changed

- feat(gg): do checkout + .gg/.ticket.json ticket marker; TS format no direct eslint & P:\programs\flutter/bin/internal/exit_with_errorlevel.bat
- gg_multi: changed references to git

## 4.2.1 - 2026-06-26

### Changed

- gg_multi: changed references to git

## 4.2.0 - 2026-06-19

### Changed

- Publish bridges as TypeScript: pnpm-aware publish, dual-manifest version bump, non-swallowed publish errors, idempotent resume, review skips merged repos, link: for local TS deps, package.json scripts check
- gg_multi: changed references to git

## 4.1.0 - 2026-06-08

### Added

- Add .gitattributes file, configuring the EOL as LF
- Enable caching in pipelines

### Changed

- Enable pipelines with caching
- Update CHANGELOG.md
- Recalc hashes
- feat: read package version via gg_lang Manifest (Dart pubspec + TypeScript package.json)
- feat(do add): auto-clone transitive deps into master before graph build & P:\programs\flutter/bin/internal/exit_with_errorlevel.bat
- gg_multi: changed references to git
- gg_multi: changed references to git
- gg_multi: changed references to git
- Gg Multi: changed references to pub.dev

### Fixed

- Fix pipeline

## 4.0.4 - 2025-08-11

### Changed

- Update to gg_git 3.0.0

## 4.0.3 - 2024-04-13

### Removed

- dependency to gg_install_gg, remove ./check script
- dependency pana

## 4.0.2 - 2024-04-11

### Changed

- Upgrade dependencies

## 4.0.1 - 2024-04-09

### Removed

- 'Pipline: Disable cache'

## 4.0.0 - 2024-04-09

### Changed

- BREAKING CHANGE: FromChangelog returns null when no version is contained

## 3.0.1 - 2024-04-08

### Added

- AllVersion.get() add option to ignore uncommitted changes

### Removed

- sample_package used to test the functions moved to gg_publish

## 3.0.0 - 2024-04-08

### Changed

- Rework changelog + repository URL in pubspec.yaml
- 'Github Actions Pipeline'
- 'Github Actions Pipeline: Add SDK file containing flutter into .github/workflows to make github installing flutter and not dart SDK'

### Removed

- pubspec.lock
- Add pubspec.lock to .gitignore
- test/sample_package/pubspec.lock
- test/sample_package/pubspec.lock after test execution
- Breaking change: Move PrepareNextVersion, PublishedVersion, IsVersionPrepared to GgPublish library

## 2.0.2 - 2024-01-01

- `IsVersionPrepared`: `treatUnpublishedAsOk` can be set using constructor

## 2.0.1 - 2024-01-01

- [Unreleased] section at the beginning of CHANGELOG.md will not affect `FromChangeLog`
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
is_versionsed or consistent_version

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
