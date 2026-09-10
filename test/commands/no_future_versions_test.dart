// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:gg_version/gg_version.dart';
import 'package:test/test.dart';

import 'package:gg_git/gg_git_test_helpers.dart';

/// The message without its color escapes.
String plain(String message) =>
    message.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');

void main() {
  late Directory tmp;
  late Directory d;
  final messages = <String>[];

  late NoFutureVersions noFutureVersions;
  late CommandRunner<void> runner;

  // ...........................................................................
  Future<void> writeChangelog(String content) =>
      File('${d.path}/CHANGELOG.md').writeAsString(content);

  // ...........................................................................
  setUp(() async {
    tmp = await Directory.systemTemp.createTemp();
    d = Directory('${tmp.path}/test');
    await d.create();
    noFutureVersions = NoFutureVersions(
      ggLog: (msg) => messages.add(rmControls(msg)),
    );
    runner = CommandRunner<void>('test', 'test')
      ..addCommand(
        NoFutureVersions(ggLog: (msg) => messages.add(rmControls(msg))),
      );
    messages.clear();
  });

  // ...........................................................................
  tearDown(() {
    tmp.deleteSync(recursive: true);
  });

  group('NoFutureVersions', () {
    group('get(directory)', () {
      group('should return true', () {
        test('when the directory has no manifest', () async {
          await writeChangelog('# Changelog\n\n## 9.9.9\n');

          expect(
            await noFutureVersions.get(directory: d, ggLog: messages.add),
            isTrue,
          );
          expect(messages.last, contains('No manifest'));
        });

        test('when the directory has no CHANGELOG.md', () async {
          await addPubspecFileWithoutCommitting(d, version: '1.2.3');

          expect(
            await noFutureVersions.get(directory: d, ggLog: messages.add),
            isTrue,
          );
          expect(messages.last, contains('No CHANGELOG.md'));
        });

        test('when every section is at or below the manifest', () async {
          await addPubspecFileWithoutCommitting(d, version: '1.2.3');
          await writeChangelog(
            '# Changelog\n\n'
            '## Unreleased\n\n- pending\n\n'
            '## [1.2.3] - 2024-04-09\n\n'
            '## 1.2.2\n\n'
            '## 1.0.0-beta.1\n',
          );

          expect(
            await noFutureVersions.get(directory: d, ggLog: messages.add),
            isTrue,
          );
          expect(messages.last, 'CHANGELOG.md has no version above 1.2.3.');
        });

        test('when only »## Unreleased« sits above the manifest', () async {
          await addPubspecFileWithoutCommitting(d, version: '1.2.3');
          await writeChangelog('# Changelog\n\n## Unreleased\n\n## 1.2.3\n');

          expect(
            await noFutureVersions.get(directory: d, ggLog: messages.add),
            isTrue,
          );
        });
      });

      group('should return false and name the sections', () {
        test('when the first section is above the manifest', () async {
          await addPubspecFileWithoutCommitting(d, version: '2.2.0');
          await writeChangelog(
            '# Changelog\n\n## Unreleased\n\n## [2.3.0] - 2024-04-09\n\n'
            '## 2.2.0\n',
          );

          expect(
            await noFutureVersions.get(directory: d, ggLog: messages.add),
            isFalse,
          );
          expect(
            messages.last,
            'CHANGELOG.md lists a version above the manifest version '
            '2.2.0: 2.3.0. Move the entries under "## Unreleased" or remove '
            'the section — the release writes the new version itself.',
          );
        });

        test('when a later section is above the manifest', () async {
          await addPubspecFileWithoutCommitting(d, version: '2.2.0');
          await writeChangelog(
            '# Changelog\n\n## 2.2.0\n\n## 3.0.0\n\n## 2.1.0\n\n## 2.5.0\n',
          );

          expect(
            await noFutureVersions.get(directory: d, ggLog: messages.add),
            isFalse,
          );
          expect(
            messages.last,
            'CHANGELOG.md lists versions above the manifest version '
            '2.2.0: 3.0.0, 2.5.0. Move the entries under "## Unreleased" or '
            'remove the section — the release writes the new version itself.',
          );
        });
      });
    });

    group('exec(directory)', () {
      test('should print »✓ CHANGELOG.md has no version above the manifest« '
          'and return true when the check passes', () async {
        await addPubspecFileWithoutCommitting(d, version: '1.2.3');
        await writeChangelog('# Changelog\n\n## 1.2.3\n');

        final result = await noFutureVersions.exec(
          directory: d,
          ggLog: messages.add,
        );

        expect(result, isTrue);
        expect(
          plain(messages[0]),
          contains('⌛️ CHANGELOG.md has no version above the manifest.'),
        );
        expect(
          plain(messages[1]),
          contains('✓ CHANGELOG.md has no version above the manifest.'),
        );
      });

      test('should throw when a section is above the manifest', () async {
        await addPubspecFileWithoutCommitting(d, version: '1.2.3');
        await writeChangelog('# Changelog\n\n## 1.3.0\n\n## 1.2.3\n');

        await expectLater(
          noFutureVersions.exec(directory: d, ggLog: messages.add),
          throwsA(
            isA<Exception>().having(
              (e) => plain(e.toString()),
              'message',
              contains(
                'CHANGELOG.md lists a version above the manifest version '
                '1.2.3: 1.3.0.',
              ),
            ),
          ),
        );
        expect(
          plain(messages[1]),
          contains('✗ CHANGELOG.md has no version above the manifest.'),
        );
      });

      test('should be available via the command runner', () async {
        await addPubspecFileWithoutCommitting(d, version: '1.2.3');
        await writeChangelog('# Changelog\n\n## 1.3.0\n');

        await expectLater(
          runner.run(['no-future-versions', '--input', d.path]),
          throwsA(
            isA<Exception>().having(
              (e) => plain(e.toString()),
              'message',
              contains('1.2.3: 1.3.0'),
            ),
          ),
        );
      });
    });
  });
}
