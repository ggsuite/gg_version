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
  late FromPubspec fromPubspec;

  setUp(() {
    d = initTestDir();
    fromPubspec = FromPubspec(log: messages.add);
    messages.clear();
  });

  group('PubSpecVersion', () {
    group('fromDirectory(directory)', () {
      group('should throw', () {
        test('if no pubspec.yaml file is found in directory', () async {
          await expectLater(
            () => fromPubspec.fromDirectory(
              directory: d,
            ),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                'Exception: File "test/pubspec.yaml" does not exist.',
              ),
            ),
          );
        });
      });

      group('should return version', () {
        test('when found in pubspec.yaml', () async {
          await setPubspec(d, version: '0.0.1');
          final version = await fromPubspec.fromDirectory(
            directory: d,
          );
          expect(version, Version.parse('0.00.001'));
        });
      });
    });

    group('fromString(content)', () {
      group('should throw', () {
        // .....................................................................
        test('if pubspec.yaml has no version tag', () {
          const content = 'name: test';

          expect(
            () => fromPubspec.fromString(content: content),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                'Exception: Could not find version in "pubspec.yaml".',
              ),
            ),
          );
        });

        // .....................................................................
        test('if pubspec.yaml contains invalid version', () {
          const content = 'name: test\nversion: 0.x.7';

          expect(
            () => fromPubspec.fromString(content: content),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains(
                  'Unsupported value for "version". Could not parse "0.x.7".',
                ),
              ),
            ),
          );
        });
      });

      group('should succeed', () {
        test('and return the version foun in pubspec.yaml', () {
          const content = 'name: test\nversion: 1.2.3';
          final version = fromPubspec.fromString(content: content);
          expect(version, Version.parse('01.02.003'));
        });
      });
    });

    group('run()', () {
      group('should return the version', () {
        test('when found in pubspec.yaml', () async {
          await setPubspec(d, version: '4.5.7');
          final runner = CommandRunner<void>('test', 'test')
            ..addCommand(FromPubspec(log: messages.add));

          await runner.run(['from-pubspec', '--input', d.path]);
          expect(messages.last, '4.5.7');
        });
      });
    });
  });
}
