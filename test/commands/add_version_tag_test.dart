// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_version/gg_version.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:gg_git/gg_git_test_helpers.dart';

// .............................................................................
class GgProcessWrapperMock extends Mock implements GgProcessWrapper {}

// .............................................................................
void main() {
  late Directory tmp;
  late Directory d;

  final messages = <String>[];
  late CommandRunner<void> runner;
  late AddVersionTag addVersionTag;

  // ...........................................................................
  void initCommand({
    GgProcessWrapper? processWrapper,
  }) {
    addVersionTag = AddVersionTag(
      ggLog: messages.add,
      processWrapper: processWrapper ?? const GgProcessWrapper(),
    );
    runner.addCommand(addVersionTag);
  }

  // ...........................................................................
  setUp(() async {
    runner = CommandRunner<void>('test', 'test');
    tmp = await Directory.systemTemp.createTemp();
    d = Directory('${tmp.path}/test');
    await d.create();
    messages.clear();
  });

  // ...........................................................................
  tearDown(() {
    tmp.deleteSync(recursive: true);
  });

  group('GgAddVersionTag', () {
    group('add(...)', () {
      group('should throw', () {
        test('if there are uncommited changes', () async {
          initCommand();
          await initGit(d);
          await setPubspec(d, version: '0.0.1');

          await expectLater(
            addVersionTag.add(
              ggLog: messages.add,
              directory: d,
            ),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                'Not everything is commited.',
              ),
            ),
          );
        });

        test(
          'when version in pubspec does not equal version in changeLog',
          () async {
            initCommand();
            await initGit(d);

            // Set pubspec and changeLog version to different values
            await setupVersions(
              d,
              changeLog: '0.0.2',
              pubspec: '0.0.3',
              gitHead: null,
            );

            // Call add(...) should tell us to fix different versions
            await expectLater(
              addVersionTag.add(
                ggLog: messages.add,
                directory: d,
              ),
              throwsA(
                isA<Exception>().having(
                  (e) => e.toString(),
                  'message',
                  'Exception: Version in pubspec.yaml is not equal version in '
                      'CHANGELOG.md.',
                ),
              ),
            );
          },
        );

        test('if Head already has a version tag', () async {
          initCommand();
          await initGit(d);

          // Set pubspec and changeLog version to the same value
          // Git tag is also set, but to a different value
          await setupVersions(
            d,
            changeLog: '0.0.1',
            pubspec: '0.0.1',
            gitHead: '0.0.2',
          );

          // Call add(...) should tell us to fix different versions
          await expectLater(
            addVersionTag.add(
              ggLog: messages.add,
              directory: d,
            ),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                'Exception: Head has already a version tag.',
              ),
            ),
          );
        });

        test('if a higher version exists in a previous commit', () async {
          initCommand();
          await initGit(d);

          // A older commit does set a higher version
          await setupVersions(
            d,
            changeLog: '0.0.2',
            pubspec: '0.0.2',
            gitHead: '0.0.2',
          );

          // A newer commit does set a lower version
          await setupVersions(
            d,
            changeLog: '0.0.1',
            pubspec: '0.0.1',
            gitHead: null,
          );

          // When adding the version tag, we should get an exception
          await expectLater(
            addVersionTag.add(
              ggLog: messages.add,
              directory: d,
            ),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                'Exception: Version in pubspec.yaml and CHANGELOG.md must be '
                    'greater 0.0.2',
              ),
            ),
          );
        });

        test('if something wents wrong while calling git tag', () async {
          await initGit(d);
          await setupVersions(
            d,
            changeLog: '0.0.1',
            pubspec: '0.0.1',
            gitHead: null,
          );

          // Mock calls of "git"
          final processWrapper = GgProcessWrapperMock();
          when(
            () => processWrapper.run(
              any(),
              any(),
              workingDirectory: any(named: 'workingDirectory'),
            ),
          ).thenAnswer((x) async {
            final binary = x.positionalArguments.first;
            expect(binary, 'git');
            final args = x.positionalArguments[1] as List<String>;

            // Mock git tag
            if (args.first == 'tag') {
              // Listing tags does not return any tag
              if (args[1] == '-l') {
                return ProcessResult(1, 0, '', '');
              }

              // Setting tag returns an error
              if (args[1] == '-a') {
                return ProcessResult(1, 1, '', 'Error 123');
              }
            }

            // Return success for all other calls
            return ProcessResult(1, 0, '', '');
          });

          initCommand(processWrapper: processWrapper);

          // When adding the version tag, we should get an exception
          await expectLater(
            addVersionTag.add(
              ggLog: messages.add,
              directory: d,
            ),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                'Exception: Could not add tag 0.0.1: Error 123',
              ),
            ),
          );
        });
      });

      group('should return true', () {
        group('and add no tag', () {
          test(
              'when pubspec, CHANGELOG.md and tag '
              'have already the same version', () async {
            await initGit(d);

            // Set pubspec and changeLog version to the same value
            await setupVersions(
              d,
              changeLog: '0.0.1',
              pubspec: '0.0.1',
              gitHead: '0.0.1',
            );

            // Call add(...) should tell us to fix different versions
            final result = await addVersionTag.add(
              ggLog: messages.add,
              directory: d,
            );

            // Should return true
            expect(result, isTrue);

            // Should log that version is already set
            expect(messages.last, 'Version already set.');
          });
        });

        group('and write the pubspec version to git tag', () {
          test('when the version is not set yet', () async {
            initCommand();
            await initGit(d);

            // CHANGELOG.md and pubspec.yaml have the same version
            // but there is no git tag yet
            await setupVersions(
              d,
              changeLog: '4.5.6',
              pubspec: '4.5.6',
              gitHead: null,
            );

            // Add the tag
            final result = await addVersionTag.add(
              ggLog: messages.add,
              directory: d,
            );

            // Should return true to indicate success
            expect(result, isTrue);

            // The git head should have tag "4.5.6"
            final fromGit = FromGit(ggLog: messages.add);
            expect(
              await fromGit.fromHead(
                ggLog: messages.add,
                directory: d,
              ),
              Version(4, 5, 6),
            );

            expect(messages.last, 'Tag 4.5.6 added.');
          });
        });
      });
    });

    group('run()', () {
      group('should throw', () {
        test('if there are uncommited changes', () async {
          initCommand();
          await initGit(d);
          await setPubspec(d, version: '0.0.1');
          await expectLater(
            () => runner.run(['add-version-tag', '--input', d.path]),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                'Not everything is commited.',
              ),
            ),
          );
        });
      });
      group('add the right version tag', () {
        test('and log the success', () async {
          await initGit(d);

          // CHANGELOG.md and pubspec.yaml have the same version
          // but there is no git tag yet
          await setupVersions(
            d,
            changeLog: '4.5.6',
            pubspec: '4.5.6',
            gitHead: null,
          );

          initCommand();

          // Run add-version-tag
          await runner.run(['add-version-tag', '--input', d.path]);

          // The git head should have tag "4.5.6"
          final fromGit = FromGit(ggLog: messages.add);
          expect(
            await fromGit.fromHead(
              ggLog: messages.add,
              directory: d,
            ),
            Version(4, 5, 6),
          );

          // A log message should have been written
          expect(messages.last, 'Tag 4.5.6 added.');
        });
      });
    });
  });
}
