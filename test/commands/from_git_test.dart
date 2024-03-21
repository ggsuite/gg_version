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
  late Directory d;
  final messages = <String>[];
  late FromGit fromGit;

  // ...........................................................................
  setUp(() {
    d = initTestDir();
    fromGit = FromGit(log: messages.add);
    messages.clear();
  });

  // ...........................................................................
  group('VersionFrom', () {
    group('fromHead(...)', () {
      group('should throw', () {
        test('if directory is not a git repo', () async {
          await expectLater(
            fromGit.fromHead(directory: d),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                contains('is not a git repository'),
              ),
            ),
          );
        });

        test('if there are multiple version tags for the latest revision',
            () async {
          await initGit(d);
          addAndCommitSampleFile(d);
          await addTags(d, ['0.1.0', '0.2.0']);
          await expectLater(
            fromGit.fromHead(directory: d),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                contains(
                  'There are multiple version tags for the latest revision.',
                ),
              ),
            ),
          );
        });
      });

      group('should return', () {
        group('null,', () {
          test('when no version tag is added', () async {
            await initGit(d);
            addAndCommitSampleFile(d);
            await addTags(d, ['X', 'ABC']); // No version tags
            expect(fromGit.fromHead(directory: d), completion(isNull));
          });
        });

        group('the version tag', () {
          test('when a version tag is added', () async {
            await initGit(d);
            addAndCommitSampleFile(d);
            await addTags(d, ['0.1.0']);
            expect(
              fromGit.fromHead(directory: d),
              completion(
                equals(Version(0, 1, 0)),
              ),
            );
          });
        });
      });
    });

    group('latest(...)', () {
      group('should return', () {
        group('nothing', () {
          test('when no version tag is added', () async {
            await initGit(d);
            addAndCommitSampleFile(d);
            await addTags(d, ['X', 'ABC']); // No version tags
            expect(
              fromGit.latest(
                log: messages.add,
                directory: d,
              ),
              completion(isNull),
            );
          });

          group('the version tag', () {
            group('from head revision', () {
              test('when available', () async {
                await initGit(d);
                addAndCommitSampleFile(d);
                await addTags(d, ['0.1.0']); // Old revision

                await updateAndCommitSampleFile(d);
                await addTags(d, ['0.2.0']); // Head revision
                expect(
                  fromGit.latest(
                    log: messages.add,
                    directory: d,
                  ),
                  completion(equals(Version(0, 2, 0))),
                );
              });
            });

            group('with the highest version number', () {
              test('if the latest version is lower previous one', () async {
                await initGit(d);
                addAndCommitSampleFile(d);
                await addTags(d, ['2.0.0']); // Old revision
                await updateAndCommitSampleFile(d);
                await addTags(d, ['1.0.0']); // Head revision, no version tag
                expect(
                  fromGit.latest(
                    log: messages.add,
                    directory: d,
                  ),
                  completion(equals(Version(2, 0, 0))),
                );
              });

              test('if the latest version is higher previous one', () async {
                await initGit(d);
                addAndCommitSampleFile(d);
                await addTags(d, ['1.0.0']); // Old version is higher then head
                await updateAndCommitSampleFile(d);
                await addTags(d, ['2.0.0']); // New version is lower then head
                expect(
                  fromGit.latest(
                    log: messages.add,
                    directory: d,
                  ),
                  completion(equals(Version(2, 0, 0))), // New version
                );
              });
            });
          });
        });
      });
    });

    group('run()', () {
      group('should log', () {
        group('the head version tag', () {
          test('when called with "--head-only', () async {
            await initGit(d);
            addAndCommitSampleFile(d);
            await addTags(d, ['0.1.0']);

            final runner = CommandRunner<void>('test', 'test');
            runner.addCommand(FromGit(log: messages.add));
            await runner.run(
              ['from-git', '--input', d.path, '--head-only'],
            );
            expect(messages.last, '0.1.0');
          });
        });

        group('a previous version tag', () {
          test('when called without "--head-only', () async {
            await initGit(d);
            addAndCommitSampleFile(d);
            await addTags(d, ['0.2.0']);
            await updateAndCommitSampleFile(d);

            final runner = CommandRunner<void>('test', 'test');
            runner.addCommand(FromGit(log: messages.add));

            // No version tag in head. With '--head-only' nothing is returned
            await runner.run(
              ['from-git', '--input', d.path, '--head-only'],
            );
            expect(messages.last, 'No version tag found in head.');

            // Without --head-only, the previous verion is returned
            await runner.run(['from-git', '--input', d.path]);
            expect(messages.last, '0.2.0');
          });
        });

        group('»No version tag found«', () {
          test('when no version tag is available', () async {
            await initGit(d);
            addAndCommitSampleFile(d);
            await addTags(d, ['X', 'ABC']); // No version tags

            final runner = CommandRunner<void>('test', 'test');
            runner.addCommand(FromGit(log: messages.add));
            await runner.run(
              ['from-git', '--input', d.path, '--head-only'],
            );
            expect(messages, ['No version tag found in head.']);
          });
        });
      });
    });
  });
}
