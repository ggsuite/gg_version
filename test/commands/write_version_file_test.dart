// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_capture_print/gg_capture_print.dart';
import 'package:gg_version/gg_version.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late Directory d;
  final messages = <String>[];
  late WriteVersionFile writeVersionFile;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp();
    d = Directory('${tmp.path}/test');
    await d.create();
    writeVersionFile = WriteVersionFile(ggLog: messages.add);
    messages.clear();
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  // ...........................................................................
  void addDartPackage({String name = 'my_package', String version = '1.2.3'}) {
    File('${d.path}/pubspec.yaml')
        .writeAsStringSync('name: $name\nversion: $version\n');
  }

  void addTypeScriptPackage({
    String name = 'ts_fixture',
    String version = '1.0.0',
    Map<String, dynamic>? extra,
  }) {
    File('${d.path}/package.json').writeAsStringSync(
      jsonEncode({'name': name, 'version': version, ...?extra}),
    );
    File('${d.path}/tsconfig.json').writeAsStringSync('{}');
  }

  File sourceOf(String slug, {bool dart = true}) => File(
    dart
        ? '${d.path}/lib/src/${slug}_version.dart'
        : '${d.path}/src/${slug}_version.ts',
  );

  File testOf(String slug, {bool dart = true}) => File(
    dart
        ? '${d.path}/test/${slug}_version_test.dart'
        : '${d.path}/test/${slug}_version.test.ts',
  );

  group('WriteVersionFile', () {
    group('apply(directory)', () {
      group('for a dart package', () {
        test('should write the version file and its mirror test', () async {
          addDartPackage(name: 'my_package', version: '1.2.3');

          final written = await writeVersionFile.apply(
            directory: d,
            ggLog: messages.add,
          );

          expect(written, hasLength(2));
          expect(
            sourceOf('my_package').readAsStringSync(),
            contains("const String myPackageVersion = '1.2.3';"),
          );
          expect(
            sourceOf('my_package').readAsStringSync(),
            contains(versionFileMarker),
          );
          expect(
            testOf('my_package').readAsStringSync(),
            contains(versionFileMarker),
          );
          expect(
            testOf('my_package').readAsStringSync(),
            contains("import 'package:test/test.dart';"),
          );
        });

        test('should write the version passed in instead of the manifest '
            'version', () async {
          // The publish flow bumps the manifest and passes the new version, so
          // the released artifact reports what it was published as.
          addDartPackage(version: '1.2.3');

          await writeVersionFile.apply(
            directory: d,
            ggLog: messages.add,
            version: '2.0.0',
          );

          expect(
            sourceOf('my_package').readAsStringSync(),
            contains("const String myPackageVersion = '2.0.0';"),
          );
        });

        test('should not touch anything on a second run', () async {
          addDartPackage();
          await writeVersionFile.apply(directory: d, ggLog: messages.add);

          final written = await writeVersionFile.apply(
            directory: d,
            ggLog: messages.add,
          );

          expect(written, isEmpty);
        });

        test('should rewrite only the version literal when the version '
            'changed', () async {
          addDartPackage(version: '1.2.3');
          await writeVersionFile.apply(directory: d, ggLog: messages.add);
          final before = sourceOf('my_package').readAsStringSync();

          await writeVersionFile.apply(
            directory: d,
            ggLog: messages.add,
            version: '9.9.9',
          );
          final after = sourceOf('my_package').readAsStringSync();

          expect(after, isNot(before));
          expect(
            after.split('\n').length,
            before.split('\n').length,
            reason: 'the line count must stay stable across versions',
          );
          expect(
            after.replaceAll('9.9.9', '1.2.3'),
            before,
            reason: 'only the version literal may differ',
          );
        });

        test('should keep a mirror test that carries the marker', () async {
          addDartPackage();
          await writeVersionFile.apply(directory: d, ggLog: messages.add);

          final custom =
              '${testOf('my_package').readAsStringSync()}\n// hand edited\n';
          testOf('my_package').writeAsStringSync(custom);

          await writeVersionFile.apply(directory: d, ggLog: messages.add);

          expect(testOf('my_package').readAsStringSync(), custom);
        });

        test('should replace a mirror test without the marker', () async {
          // gg_test plants a boilerplate stub for any lib/src file that has no
          // test. For `<slug>_version.dart` that stub happens to assert the
          // very identifier we generate, so it compiles and passes - silently
          // disabling the self healing. The marker is what detects it.
          addDartPackage();
          await writeVersionFile.apply(directory: d, ggLog: messages.add);

          testOf('my_package').writeAsStringSync(
            "import 'package:my_package/my_package.dart';\n"
            "import 'package:test/test.dart';\n"
            '\n'
            'void main() {\n'
            "  group('MyPackageVersion', () {\n"
            "    group('method', () {\n"
            "      test('should work', () {\n"
            '        expect(myPackageVersion, isNotNull);\n'
            '      });\n'
            '    });\n'
            '  });\n'
            '}\n',
          );

          await writeVersionFile.apply(directory: d, ggLog: messages.add);

          final content = testOf('my_package').readAsStringSync();
          expect(content, contains(versionFileMarker));
          expect(content, isNot(contains('should work')));
        });
      });

      group('for a typescript package', () {
        test('should write into src and add @types/node', () async {
          addTypeScriptPackage(name: 'ts_fixture', version: '1.0.0');

          await writeVersionFile.apply(directory: d, ggLog: messages.add);

          expect(
            sourceOf('ts_fixture', dart: false).readAsStringSync(),
            contains("export const tsFixtureVersion = '1.0.0';"),
          );
          expect(
            testOf('ts_fixture', dart: false).readAsStringSync(),
            contains("from 'vitest'"),
          );

          final pkg = jsonDecode(
            File('${d.path}/package.json').readAsStringSync(),
          ) as Map<String, dynamic>;
          expect(
            (pkg['devDependencies'] as Map<String, dynamic>).keys,
            contains('@types/node'),
          );
        });

        test('should leave an existing @types/node untouched', () async {
          addTypeScriptPackage(
            extra: const {
              'devDependencies': {'@types/node': '^20.0.0'},
            },
          );

          await writeVersionFile.apply(directory: d, ggLog: messages.add);

          final pkg = jsonDecode(
            File('${d.path}/package.json').readAsStringSync(),
          ) as Map<String, dynamic>;
          expect(
            (pkg['devDependencies'] as Map<String, dynamic>)['@types/node'],
            '^20.0.0',
          );
        });

        test('should sanitize a scoped package name', () async {
          addTypeScriptPackage(name: '@scope/my-pkg', version: '3.1.4');

          await writeVersionFile.apply(directory: d, ggLog: messages.add);

          expect(sourceOf('my_pkg', dart: false).existsSync(), isTrue);
          expect(
            sourceOf('my_pkg', dart: false).readAsStringSync(),
            contains("export const myPkgVersion = '3.1.4';"),
          );
          // No accidental nested directory from the scope.
          expect(Directory('${d.path}/src/@scope').existsSync(), isFalse);
        });
      });

      group('for a bridge package', () {
        test(
          'should write both languages using each own manifest name',
          () async {
            // checkProjectType reports typescript, detectProjectType reports
            // dart. Writing only one of them would leave the other language's
            // constant permanently stale.
            addTypeScriptPackage(name: '@scope/bridge', version: '2.5.0');
            File('${d.path}/pubspec.yaml')
                .writeAsStringSync('name: bridge_dart\nversion: 2.5.0\n');

            await writeVersionFile.apply(directory: d, ggLog: messages.add);

            expect(
              sourceOf('bridge', dart: false).readAsStringSync(),
              contains("export const bridgeVersion = '2.5.0';"),
            );
            expect(
              sourceOf('bridge_dart').readAsStringSync(),
              contains("const String bridgeDartVersion = '2.5.0';"),
            );
            expect(testOf('bridge', dart: false).existsSync(), isTrue);
            expect(testOf('bridge_dart').existsSync(), isTrue);
          },
        );
      });

      group('for a project without a manifest', () {
        test('should write nothing and say so', () async {
          final written = await writeVersionFile.apply(
            directory: d,
            ggLog: messages.add,
          );

          expect(written, isEmpty);
          expect(messages.last, contains('No manifest found'));
        });
      });

      group('for a manifest without a name', () {
        test('should write nothing rather than break its host', () async {
          // The generator also runs as a side effect of IncreaseBuild and
          // PrepareNextVersion, so a degenerate manifest must not make those
          // commands fail.
          File('${d.path}/pubspec.yaml')
              .writeAsStringSync('version: 1.2.3+4\n');

          final written = await writeVersionFile.apply(
            directory: d,
            ggLog: messages.add,
          );

          expect(written, isEmpty);
          expect(messages.last, contains('No "name"'));
        });
      });

      group('should throw', () {
        test('when the manifest carries no version', () async {
          File('${d.path}/pubspec.yaml')
              .writeAsStringSync('name: my_package\n');

          await expectLater(
            writeVersionFile.apply(directory: d, ggLog: messages.add),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('"version:" not found'),
              ),
            ),
          );
        });
      });
    });

    group('run()', () {
      test('should write the version file', () async {
        addDartPackage(version: '4.5.6');
        final runner = CommandRunner<void>('test', 'test')
          ..addCommand(WriteVersionFile(ggLog: messages.add));

        await capturePrint(
          ggLog: messages.add,
          code: () async =>
              runner.run(['write-version-file', '--input', d.path]),
        );

        expect(
          sourceOf('my_package').readAsStringSync(),
          contains("const String myPackageVersion = '4.5.6';"),
        );
      });
    });
  });
}
