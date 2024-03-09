// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_version/gg_version.dart';
import 'package:test/test.dart';

import 'package:gg_git/gg_git_test_helpers.dart';

void main() {
  final messages = <String>[];
  late Directory d;

  // ...........................................................................
  setUp(() {
    d = initTestDir();
    messages.clear();
  });

  // ...........................................................................
  tearDown(() {
    d.deleteSync(recursive: true);
  });

  // ...........................................................................
  group('IsConsistent', () {
    group('run()', () {
      group('should throw', () {
        group('and print »❌ Versions are consistent«', () {
          group('when pubspec.yaml, CHANGELOG.md as well git tag', () {
            test('are not the same', () async {
              final runner = CommandRunner<void>('test', 'test')
                ..addCommand(IsConsistent(log: messages.add));

              await initGit(d);
              await setupVersions(
                d,
                pubspec: '1.2.4',
                changeLog: '1.2.3',
                gitHead: '1.2.3',
              );

              await expectLater(
                runner.run(['is-consistent', '--input', d.path]),
                throwsA(
                  isA<Exception>().having(
                    (e) => e.toString(),
                    'message',
                    contains('Versions are not consistent'),
                  ),
                ),
              );

              expect(messages[0], contains('⌛️ Versions are consistent'));
              expect(messages[1], contains('❌ Versions are consistent'));
            });
          });
        });
      });

      group('should print', () {
        group(' »✅ Versions are consistent«', () {
          test(
              'when pubspec.yaml, CHANGELOG.md as well git tag '
              'have the same version', () async {
            final runner = CommandRunner<void>('test', 'test')
              ..addCommand(IsConsistent(log: messages.add));

            await initGit(d);
            await setupVersions(
              d,
              pubspec: '1.2.3',
              changeLog: '1.2.3',
              gitHead: '1.2.3',
            );

            await runner.run(['is-consistent', '--input', d.path]);
            expect(messages[0], contains('⌛️ Versions are consistent'));
            expect(messages[1], contains('✅ Versions are consistent'));
          });
        });
      });

      test('should print errors in gray', () async {
        final runner = CommandRunner<void>('test', 'test')
          ..addCommand(IsConsistent(log: messages.add));

        await initGit(d);

        await setupVersions(
          d,
          pubspec: '1.2.3',
          changeLog: '1.2.3',
          gitHead: '1.2.4',
        );

        await initGit(d);
        await expectLater(
          runner.run(['is-consistent', '--input', d.path]),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Versions are not consistent'),
            ),
          ),
        );
      });
    });
  });
}
