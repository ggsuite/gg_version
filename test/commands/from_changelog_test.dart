// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_version/gg_version.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'package:gg_git/gg_git_test_helpers.dart';

void main() {
  late Directory tmp;
  late Directory d;
  final messages = <String>[];
  late FromChangelog fromChangelog;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp();
    d = Directory('${tmp.path}/test');
    await d.create();
    fromChangelog = FromChangelog(ggLog: messages.add);
    messages.clear();
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  group('ChangeLogVersion', () {
    group('fromDirectory(directory)', () {
      group('should throw', () {
        test('if no CHANGELOG.md file is found in directory', () async {
          await expectLater(
            () => fromChangelog.fromDirectory(directory: d),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                'Exception: File "test/CHANGELOG.md" does not exist.',
              ),
            ),
          );
        });
      });

      group('should return version', () {
        test('when found in CHANGELOG.md', () async {
          await addChangeLogWithoutCommitting(d, version: '0.0.1');
          final version = await fromChangelog.fromDirectory(directory: d);
          expect(version, Version.parse('0.00.001'));
        });
      });
    });

    group('fromString(content)', () {
      group('should throw', () {
        // .....................................................................
        test('if CHANGELOG.md has no version tag', () {
          const content = 'name: test';

          expect(
            () => fromChangelog.fromString(content: content),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                'Exception: Could not find version in "CHANGELOG.md".',
              ),
            ),
          );
        });
      });

      group('should succeed', () {
        group('and return the version foun in CHANGELOG.md', () {
          test('with cider format', () {
            const content = '# Change Log\n\n## [1.2.3] 2024-04-05\n\n- test';
            final version = fromChangelog.fromString(content: content);
            expect(version, Version.parse('01.02.003'));
          });

          test('with old gg format', () {
            const content = '# Change Log\n\n## 1.2.3\n\n- test';
            final version = fromChangelog.fromString(content: content);
            expect(version, Version.parse('01.02.003'));
          });
        });
      });
    });

    group('run()', () {
      group('should return the version', () {
        test('when found in CHANGELOG.md', () async {
          await addChangeLogWithoutCommitting(d, version: '1.0.0');
          final runner = CommandRunner<void>('test', 'test')
            ..addCommand(FromChangelog(ggLog: messages.add));

          await runner.run(['from-changelog', '--input', d.path]);
          expect(messages.last, '1.0.0');
        });
      });
    });
  });
}
