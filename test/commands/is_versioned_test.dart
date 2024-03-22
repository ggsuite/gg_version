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
  late IsVersioned isVersioned;
  late CommandRunner<void> runner;

  // ...........................................................................
  setUp(() {
    d = initTestDir();
    isVersioned = IsVersioned(log: messages.add);
    messages.clear();
    runner = CommandRunner<void>('test', 'test')
      ..addCommand(IsVersioned(log: messages.add));
  });

  // ...........................................................................
  tearDown(() {
    d.deleteSync(recursive: true);
  });

  // ...........................................................................
  group('IsConsistent', () {
    group('run(directory)', () {
      group('should throw', () {
        group('and print »❌ Versions are consistent«', () {
          group('when pubspec.yaml, CHANGELOG.md as well git tag', () {
            test('are not the same', () async {
              await initGit(d);
              await setupVersions(
                d,
                pubspec: '1.2.4',
                changeLog: '1.2.3',
                gitHead: '1.2.3',
              );

              await expectLater(
                runner.run(['is-versioned', '--input', d.path]),
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
          group(
              'when pubspec.yaml, CHANGELOG.md as well git tag '
              'have the same version', () {
            test('using command runner', () async {
              await initGit(d);
              await setupVersions(
                d,
                pubspec: '1.2.3',
                changeLog: '1.2.3',
                gitHead: '1.2.3',
              );

              await runner.run(['is-versioned', '--input', d.path]);
              expect(messages[0], contains('⌛️ Versions are consistent'));
              expect(messages[1], contains('✅ Versions are consistent'));
            });

            test('using isVersioned.run()', () async {
              await initGit(d);
              await setupVersions(
                d,
                pubspec: '1.2.3',
                changeLog: '1.2.3',
                gitHead: '1.2.3',
              );

              await isVersioned.run(directory: d);
              expect(messages[0], contains('⌛️ Versions are consistent'));
              expect(messages[1], contains('✅ Versions are consistent'));
            });
          });

          group('with ignoreVersion ==', () {
            group('pubspec', () {
              test('with command runner', () async {
                await initGit(d);
                await setupVersions(
                  d,
                  pubspec: '2.0.0',
                  changeLog: '1.2.3',
                  gitHead: '1.2.3',
                );

                await runner.run([
                  'is-versioned',
                  '--input',
                  d.path,
                  '--ignore-version',
                  'pubspec',
                ]);

                expect(messages[0], contains('⌛️ Versions are consistent'));
                expect(messages[1], contains('✅ Versions are consistent'));
              });

              test('with isVersioned.run()', () async {
                await initGit(d);
                await setupVersions(
                  d,
                  pubspec: '2.0.0',
                  changeLog: '1.2.3',
                  gitHead: '1.2.3',
                );

                await isVersioned.run(
                  directory: d,
                  ignoreVersion: VersionType.pubspec,
                );

                expect(messages[0], contains('⌛️ Versions are consistent'));
                expect(messages[1], contains('✅ Versions are consistent'));
              });
            });

            test('changeLog', () async {
              await initGit(d);
              await setupVersions(
                d,
                pubspec: '1.2.3',
                changeLog: '2.0.0',
                gitHead: '1.2.3',
              );

              await runner.run([
                'is-versioned',
                '--input',
                d.path,
                '--ignore-version',
                'changeLog',
              ]);

              expect(messages[0], contains('⌛️ Versions are consistent'));
              expect(messages[1], contains('✅ Versions are consistent'));
            });

            test('gitHead', () async {
              await initGit(d);
              await setupVersions(
                d,
                pubspec: '1.2.3',
                changeLog: '1.2.3',
                gitHead: '2.0.0',
              );

              await runner.run([
                'is-versioned',
                '--input',
                d.path,
                '--ignore-version',
                'gitHead',
              ]);

              expect(messages[0], contains('⌛️ Versions are consistent'));
              expect(messages[1], contains('✅ Versions are consistent'));
            });
          });
        });
      });

      test('should print errors in gray', () async {
        final runner = CommandRunner<void>('test', 'test')
          ..addCommand(IsVersioned(log: messages.add));

        await initGit(d);

        await setupVersions(
          d,
          pubspec: '1.2.3',
          changeLog: '1.2.3',
          gitHead: '1.2.4',
        );

        await initGit(d);
        await expectLater(
          runner.run(['is-versioned', '--input', d.path]),
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

    group('get(directory, VersionType? ignoreVersion)', () {
      group('should return true', () {
        group('when pubspec.yaml, CHANGELOG.md and git have the same version',
            () {
          test('with ignoreVersion == null', () async {
            await initGit(d);
            await setupVersions(
              d,
              pubspec: '1.2.3',
              changeLog: '1.2.3',
              gitHead: '1.2.3',
            );

            final result = await isVersioned.get(
              log: messages.add,
              directory: d,
            );

            expect(result, isTrue);
            expect(messages[0], contains('1.2.3'));
          });

          group('with ignoreVersion ==', () {
            test('pubspec', () async {
              await initGit(d);

              // Pubspec has a different version
              await setupVersions(
                d,
                pubspec: '2.0.0',
                changeLog: '1.2.3',
                gitHead: '1.2.3',
              );

              // But pubspec is ignored
              final result = await isVersioned.get(
                log: messages.add,
                directory: d,
                ignoreVersion: VersionType.pubspec,
              );

              // Therefore result is true though
              expect(result, isTrue);
              expect(messages[0], contains('1.2.3'));
            });

            test('changeLog', () async {
              await initGit(d);

              // ChangeLog has a different version
              await setupVersions(
                d,
                pubspec: '1.2.3',
                changeLog: '2.0.0',
                gitHead: '1.2.3',
              );

              // But changeLog is ignored
              final result = await isVersioned.get(
                log: messages.add,
                directory: d,
                ignoreVersion: VersionType.changeLog,
              );

              // Therefore result is true though
              expect(result, isTrue);
              expect(messages[0], contains('1.2.3'));
            });

            test('gitHead', () async {
              await initGit(d);

              // GitHead has a different version
              await setupVersions(
                d,
                pubspec: '1.2.3',
                changeLog: '1.2.3',
                gitHead: '2.0.0',
              );

              // But gitHead is ignored
              final result = await isVersioned.get(
                log: messages.add,
                directory: d,
                ignoreVersion: VersionType.gitHead,
              );

              // Therefore result is true though
              expect(result, isTrue);
              expect(messages[0], contains('1.2.3'));
            });
          });
        });
      });

      group('should return false', () {
        test('when pubspec.yaml, CHANGELOG.md and git have different versions',
            () async {
          await initGit(d);
          await setupVersions(
            d,
            pubspec: '1.2.3',
            changeLog: '1.2.3',
            gitHead: '1.2.4',
          );

          final result = await isVersioned.get(
            log: messages.add,
            directory: d,
          );

          expect(result, isFalse);
          expect(
            messages[0],
            'Exception: Versions are not consistent: - pubspec: 1.2.3, '
            '- changeLog: 1.2.3, - gitHead: 1.2.4',
          );
        });
      });
    });
  });
}
