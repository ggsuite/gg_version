// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:gg_version/gg_version.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late Directory d;
  final messages = <String>[];
  late AllVersions allVersions;

  // ...........................................................................
  setUp(() async {
    tmp = await Directory.systemTemp.createTemp();
    d = Directory('${tmp.path}/test');
    await d.create();
    messages.clear();
    allVersions = AllVersions(ggLog: messages.add);
  });

  // ...........................................................................
  tearDown(() {
    tmp.deleteSync(recursive: true);
  });

  group('AllVersions', () {
    group('get(directory, log, dirName)', () {
      group('should throw', () {
        test('when something is wrong', () async {
          // Don't create a git repository.
          // Run command
          await expectLater(
            allVersions.get(
              ggLog: messages.add,
              directory: d,
            ),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.toString(),
                'message',
                contains('Directory "test" is not a git repository'),
              ),
            ),
          );

          expect(messages, isEmpty);
        });
      });

      group('should return the versions', () {
        group('found int pubspec, CHANGELOG and git tag', () {
          group('if everything is commited ', () {
            test('and head revision has version tag', () async {
              await initGit(d);

              // Set old revision
              await setupVersions(
                d,
                pubspec: '1.2.3',
                changeLog: '4.5.6',
                gitHead: '7.8.9',
              );

              // Set head revision
              await setupVersions(
                d,
                pubspec: '2.2.3',
                changeLog: '5.5.6',
                gitHead: '8.8.9',
              );

              final result = await allVersions.get(
                ggLog: (m) => messages.add(m),
                directory: d,
              );

              // Latest version should be returned
              expect(result.pubspec, Version.parse('2.2.3'));
              expect(result.changeLog, Version.parse('5.5.6'));
              expect(result.gitHead, Version.parse('8.8.9'));
              expect(result.gitLatest, Version.parse('8.8.9'));
            });

            test('and no revision has a version tag', () async {
              await initGit(d);
              await setupVersions(
                d,
                pubspec: '1.2.3',
                changeLog: '1.2.3',
                gitHead: null,
              );

              final result = await allVersions.get(
                ggLog: (m) => messages.add(m),
                directory: d,
              );

              expect(result.pubspec.toString(), '1.2.3');
              expect(result.changeLog.toString(), '1.2.3');
              expect(result.gitHead, null);
              expect(result.gitLatest, null);
            });

            test('only previous revisions have a version tag', () async {
              await initGit(d);
              // Set old revision
              await setupVersions(
                d,
                pubspec: '1.2.3',
                changeLog: '4.5.6',
                gitHead: '7.8.9',
              );

              // Add another commit
              await updateAndCommitSampleFile(d);

              // Get versions
              final result = await allVersions.get(
                ggLog: (m) => messages.add(m),
                directory: d,
              );

              // Latest version should be returned
              expect(result.pubspec, Version.parse('1.2.3'));
              expect(result.changeLog, Version.parse('4.5.6'));
              expect(result.gitHead, null); // Head has no version
              expect(result.gitLatest, Version.parse('7.8.9'));
            });
          });
        });
      });
    });

    group('run()', () {
      group('should log the versions', () {
        group('found in pubspec.yaml, CHANGELOg.md, and git', () {
          test('when everything is commited', () async {
            final runner = CommandRunner<void>('test', 'test')
              ..addCommand(allVersions);

            await initGit(d);
            await setupVersions(
              d,
              pubspec: '1.2.3',
              changeLog: '1.2.3',
              gitHead: '1.2.3',
            );

            await runner.run(['all-versions', '--input', d.path]);
            expect(messages[0], 'pubspec: 1.2.3');
            expect(messages[1], 'changelog: 1.2.3');
            expect(messages[2], 'git head: 1.2.3');
            expect(messages[3], 'git latest: 1.2.3');
          });

          test('when not everything is commited', () async {
            final runner = CommandRunner<void>('test', 'test')
              ..addCommand(AllVersions(ggLog: messages.add));

            await initGit(d);
            await setupVersions(
              d,
              pubspec: '1.2.3',
              changeLog: '1.2.3',
              gitHead: '1.2.3',
            );

            // Change the version of pubspec.yaml without committing
            await setPubspec(d, version: '2.2.3');

            await runner.run(['all-versions', '--input', d.path]);
            expect(messages[0], 'pubspec: 2.2.3');
            expect(messages[1], 'changelog: 1.2.3');
            expect(messages[2], 'git head: -');
            expect(messages[3], 'git latest: 1.2.3');
          });
        });
      });

      group('should throw', () {
        test('if something wents wrong', () async {
          final runner = CommandRunner<void>('test', 'test')
            ..addCommand(AllVersions(ggLog: messages.add));

          await initGit(d);
          await initUncommittedFile(d);
          await expectLater(
            runner.run(['all-versions', '--input', d.path]),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Exception: File "test/pubspec.yaml" does not exist.'),
              ),
            ),
          );
        });
      });
    });
  });
}
