// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:gg_version/gg_version.dart';
import 'package:gg_version/src/commands/consistent_version.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];
  late Directory d;

  // ...........................................................................
  Future<Version> getVersion() => ConsistentVersion.get(
        directory: d,
        log: (m) => messages.add(m),
      );

  // ...........................................................................
  setUp(() {
    d = initTestDir();
    messages.clear();
  });

  // ...........................................................................
  tearDown(() {
    d.deleteSync(recursive: true);
  });

  group('ConsistentVersion', () {
    group('get(directory, processWrapper, log)', () {
      group('should throw', () {
        test('if CHANGELOG version does not match the others', () async {
          await initGit(d);
          await setupVersions(
            d,
            pubspec: '1.0.0',
            changeLog: '2.0.0',
            gitHead: '1.0.0',
          );

          await expectLater(
            () => getVersion(),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Versions are not consistent:'),
              ),
            ),
          );
        });

        test('if no git version tag exists', () async {
          await initGit(d);
          await setupVersions(
            d,
            pubspec: '1.0.0',
            changeLog: '1.0.0',
            gitHead: null,
          );

          await expectLater(
            () => getVersion(),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Current state has no git version tag.'),
              ),
            ),
          );
        });

        test('if Pubspec version does not match the others', () async {
          await initGit(d);
          await setupVersions(
            d,
            pubspec: '2.0.0',
            changeLog: '1.0.0',
            gitHead: '1.0.0',
          );

          await expectLater(
            () => getVersion(),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Versions are not consistent:'),
              ),
            ),
          );
        });

        test('if Git head version does not match the others', () async {
          await initGit(d);
          await setupVersions(
            d,
            pubspec: '1.0.0',
            changeLog: '1.0.0',
            gitHead: '0.0.0',
          );

          await expectLater(
            () => getVersion(),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Versions are not consistent:'),
              ),
            ),
          );
        });
      });

      group('should return the consistent version', () {
        test('if all versions are consistent', () async {
          await initGit(d);
          await setupVersions(
            d,
            pubspec: '1.2.3',
            changeLog: '1.2.3',
            gitHead: '1.2.3',
          );
          final result = await getVersion();
          expect(result.toString(), '1.2.3');
        });
      });
    });

    group('run()', () {
      test('should return the consistent version', () async {
        final runner = CommandRunner<void>('test', 'test')
          ..addCommand(ConsistentVersion(log: messages.add));

        await initGit(d);
        await setupVersions(
          d,
          pubspec: '1.2.3',
          changeLog: '1.2.3',
          gitHead: '1.2.3',
        );

        await runner.run(['consistent-version', '--input', d.path]);
        expect(messages.last, contains('1.2.3'));
      });

      test('should print errors in gray', () async {
        final runner = CommandRunner<void>('test', 'test')
          ..addCommand(ConsistentVersion(log: messages.add));

        await initGit(d);

        await setupVersions(
          d,
          pubspec: '1.2.3',
          changeLog: '1.2.3',
          gitHead: '1.2.4',
        );

        await initGit(d);
        await expectLater(
          runner.run(['consistent-version', '--input', d.path]),
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
