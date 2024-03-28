// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_version/src/commands/increase_build.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];
  final ggLog = messages.add;
  late IncreaseBuild increaseBuild;
  late Directory d;
  late File pubspecFile;

  setUp(() {
    messages.clear();
    d = Directory.systemTemp.createTempSync();
    increaseBuild = IncreaseBuild(ggLog: ggLog);
    pubspecFile = File(join(d.path, 'pubspec.yaml'));
  });

  tearDown(() {
    d.deleteSync(recursive: true);
  });

  group('IncreaseBuild', () {
    group('inString(contents)', () {
      group('should increase the build number', () {
        test('- when a build number exists', () {
          final result = increaseBuild.inString('version: 1.2.3+4');

          expect(result, 'version: 1.2.3+5');
        });

        test('- when no build number exists', () {
          final result = increaseBuild.inString('version: 1.2.3');
          expect(result, 'version: 1.2.3+1');
        });
      });
      group('should throw', () {
        test('if contents contains no version', () {
          late String exception;
          try {
            increaseBuild.inString('');
          } catch (e) {
            exception = e.toString();
          }

          expect(exception, contains('Version key not found'));
        });
      });
    });

    group('inFile(file)', () {
      test('should increase the build number in file', () async {
        await pubspecFile.writeAsString('xyz: 10\nversion: 1.2.3+4\nabc: 20');
        await increaseBuild.inFile(file: pubspecFile);
        final result = await pubspecFile.readAsString();
        expect(result, contains('version: 1.2.3+5'));
      });

      test('should throw if the file does not exist', () async {
        late String exception;
        try {
          await increaseBuild.inFile(file: File('no-such-file'));
        } catch (e) {
          exception = e.toString();
        }

        expect(exception, contains('Cannot open file'));
      });
    });

    group('exec(directory)', () {
      group('throws', () {
        test('if pubspec.yaml file does not exist', () async {
          late String exception;
          try {
            await increaseBuild.exec(directory: d, ggLog: ggLog);
          } catch (e) {
            exception = e.toString();
          }

          expect(
            exception,
            contains('pubspec.yaml file not found in ${d.path}'),
          );
        });
      });

      group('increases build in pubspec.yaml', () {
        test('when the file exists', () async {
          await pubspecFile.writeAsString('version: 1.2.3+4');
          await increaseBuild.exec(directory: d, ggLog: ggLog);
          final result = await pubspecFile.readAsString();
          expect(result, contains('version: 1.2.3+5'));
        });
      });
    });
  });
}
