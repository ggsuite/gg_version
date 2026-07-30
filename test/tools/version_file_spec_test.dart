// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_lang/gg_lang.dart';
import 'package:gg_version/gg_version.dart';
import 'package:test/test.dart';

void main() {
  group('versionFileSlug()', () {
    group('should return a file-name safe slug', () {
      for (final (input, expected) in const [
        ('gg_version', 'gg_version'),
        ('ts_fixture', 'ts_fixture'),
        ('bridge_dart', 'bridge_dart'),
        ('target-repo-ts', 'target_repo_ts'),
        ('@scope/bridge', 'bridge'),
        ('@scope/my-pkg', 'my_pkg'),
        ('MixedCase', 'mixedcase'),
        ('3d-utils', '3d_utils'),
        ('__weird__', 'weird'),
        ('@scope/', 'package'),
        ('', 'package'),
      ]) {
        test('for "$input"', () {
          expect(versionFileSlug(input), expected);
        });
      }
    });
  });

  group('versionFileIdentifier()', () {
    group('should return a valid camelCase identifier', () {
      for (final (input, expected) in const [
        ('gg_version', 'ggVersionVersion'),
        ('gg_publish', 'ggPublishVersion'),
        ('ts_fixture', 'tsFixtureVersion'),
        ('bridge', 'bridgeVersion'),
        ('target_repo_ts', 'targetRepoTsVersion'),
      ]) {
        test('for "$input"', () {
          expect(versionFileIdentifier(input), expected);
        });
      }
    });

    test('should letter-prefix a slug starting with a digit', () {
      // An underscore prefix would make the constant library private in Dart,
      // so it could never be exported from the barrel.
      expect(versionFileIdentifier('3d_utils'), 'pkg3dUtilsVersion');
      expect(versionFileIdentifier('3d_utils').startsWith('_'), isFalse);
    });

    test('should fall back when the slug carries no parts', () {
      expect(versionFileIdentifier('_'), 'packageVersion');
    });
  });

  group('VersionFileSpec', () {
    group('forProjectType()', () {
      test('should return the dart spec for dart', () {
        expect(
          VersionFileSpec.forProjectType(ProjectType.dart),
          VersionFileSpec.dartSpec,
        );
      });

      test('should return the flutter spec for flutter', () {
        expect(
          VersionFileSpec.forProjectType(ProjectType.flutter),
          VersionFileSpec.flutterSpec,
        );
      });

      test('should return the typescript spec for typescript', () {
        expect(
          VersionFileSpec.forProjectType(ProjectType.typescript),
          VersionFileSpec.typeScriptSpec,
        );
      });

      test('should return null when there is no manifest', () {
        expect(VersionFileSpec.forProjectType(ProjectType.none), isNull);
      });
    });

    group('paths', () {
      test('should place dart files in lib/src and test', () {
        const spec = VersionFileSpec.dartSpec;
        expect(
          spec.sourcePath('gg_version'),
          'lib/src/gg_version_version.dart',
        );
        expect(
          spec.testPath('gg_version'),
          'test/gg_version_version_test.dart',
        );
      });

      test('should mirror the gg_test lib/src to test mapping', () {
        // gg_test derives the expected test path by replacing `lib/src/` with
        // `test/` and `.dart` with `_test.dart`. Both must agree or the
        // `tests` check fails before running anything.
        const spec = VersionFileSpec.dartSpec;
        final derived = spec
            .sourcePath('gg_version')
            .replaceAll('lib/src/', 'test/')
            .replaceAll('.dart', '_test.dart');
        expect(derived, spec.testPath('gg_version'));
      });

      test('should place typescript files in src and test', () {
        const spec = VersionFileSpec.typeScriptSpec;
        expect(spec.sourcePath('ts_fixture'), 'src/ts_fixture_version.ts');
        expect(spec.testPath('ts_fixture'), 'test/ts_fixture_version.test.ts');
      });

      test('should resolve files inside a directory', () {
        const spec = VersionFileSpec.dartSpec;
        final dir = Directory('/tmp/pkg');
        expect(
          spec.sourceFile(dir, 'gg_version').path,
          endsWith('gg_version_version.dart'),
        );
        expect(
          spec.testFile(dir, 'gg_version').path,
          endsWith('gg_version_version_test.dart'),
        );
      });
    });

    group('declaration()', () {
      test('should be a const for dart and an export for typescript', () {
        expect(
          VersionFileSpec.dartSpec.declaration('gg_version'),
          'const String ggVersionVersion = ',
        );
        expect(
          VersionFileSpec.typeScriptSpec.declaration('ts_fixture'),
          'export const tsFixtureVersion = ',
        );
      });

      test('should contain no regexp metacharacters', () {
        // The generated test embeds this into a RegExp.
        final decl = VersionFileSpec.dartSpec.declaration('gg_version');
        expect(RegExp(r'[\\^$.|?*+()\[\]{}]').hasMatch(decl), isFalse);
      });
    });

    group('renderSource()', () {
      test('should render the dart version file', () {
        final content = VersionFileSpec.dartSpec.renderSource(
          slug: 'gg_version',
          version: '4.5.0',
          packageName: 'gg_version',
        );

        expect(content, startsWith('// @license\n// Copyright (c) ggsuite\n'));
        expect(content, contains(versionFileMarker));
        expect(content, contains('// coverage:ignore-file'));
        expect(content, contains('/// The version of the `gg_version`'));
        expect(content, contains("const String ggVersionVersion = '4.5.0';"));
        expect(content, endsWith('\n'));
      });

      test('should render the typescript version file without a header', () {
        final content = VersionFileSpec.typeScriptSpec.renderSource(
          slug: 'ts_fixture',
          version: '1.0.0',
          packageName: 'ts_fixture',
        );

        expect(content, isNot(contains('@license')));
        expect(content, contains(versionFileMarker));
        expect(content, contains("export const tsFixtureVersion = '1.0.0';"));
        expect(content, endsWith('\n'));
      });

      test('should keep the line count stable across versions', () {
        // A rewrite must never change the shape of the file, only the literal.
        String lines(String v) => VersionFileSpec.dartSpec
            .renderSource(slug: 'a_b', version: v, packageName: 'a_b')
            .split('\n')
            .length
            .toString();

        expect(lines('1.0.0'), lines('10.20.30'));
        expect(lines('1.0.0'), lines('1.0.0-rc.1'));
        expect(lines('1.0.0'), lines('1.0.0+42'));
      });
    });

    group('renderTest()', () {
      test('should render a dart test importing package:test', () {
        final content = VersionFileSpec.dartSpec.renderTest(
          slug: 'gg_version',
          manifestFile: 'pubspec.yaml',
        );

        expect(content, contains("import 'package:test/test.dart';"));
        expect(content, contains(versionFileMarker));
        expect(content, contains("File('lib/src/gg_version_version.dart')"));
        expect(content, contains("File('pubspec.yaml')"));
        // Must not import the barrel: a package that acquires its version file
        // during publishing has no export for it yet.
        expect(content, isNot(contains('package:gg_version/')));
      });

      test('should render a flutter test importing flutter_test', () {
        // package:test is not in a Flutter package's dependency closure.
        final content = VersionFileSpec.flutterSpec.renderTest(
          slug: 'gg_gui',
          manifestFile: 'pubspec.yaml',
        );

        expect(
          content,
          contains("import 'package:flutter_test/flutter_test.dart';"),
        );
        expect(content, isNot(contains("import 'package:test/test.dart';")));
      });

      test('should render a typescript test that imports the constant', () {
        // Every gg-managed TypeScript project reports src/** coverage against
        // a 100% threshold, so the module has to be loaded.
        final content = VersionFileSpec.typeScriptSpec.renderTest(
          slug: 'ts_fixture',
          manifestFile: 'package.json',
        );

        expect(
          content,
          contains(
            "import { tsFixtureVersion } from '../src/ts_fixture_version'",
          ),
        );
        expect(content, contains("from 'node:fs'"));
        expect(content, contains("from 'vitest'"));
        expect(content, contains('expect(tsFixtureVersion).toBeTruthy();'));
        // No import.meta.url / __dirname: relative paths from the project root
        // work under every module format.
        expect(content, isNot(contains('import.meta')));
        expect(content, isNot(contains('__dirname')));
      });

      test('should keep every line within 80 characters', () {
        // `lines_longer_than_80_chars` is enabled in every ggsuite package, so
        // a generated file that overflows would fail `gg check analyze`.
        for (final spec in const [
          VersionFileSpec.dartSpec,
          VersionFileSpec.flutterSpec,
          VersionFileSpec.typeScriptSpec,
        ]) {
          final manifest = spec.isDart ? 'pubspec.yaml' : 'package.json';
          final files = [
            spec.renderSource(
              slug: 'gg_localize_refs',
              version: '10.20.30-rc.1',
              packageName: 'gg_localize_refs',
            ),
            spec.renderTest(slug: 'gg_localize_refs', manifestFile: manifest),
          ];

          for (final content in files) {
            for (final line in content.split('\n')) {
              expect(
                line.length,
                lessThanOrEqualTo(80),
                reason: 'too long: $line',
              );
            }
          }
        }
      });

      test('should not depend on the version', () {
        final a = VersionFileSpec.dartSpec.renderTest(
          slug: 'gg_version',
          manifestFile: 'pubspec.yaml',
        );
        final b = VersionFileSpec.dartSpec.renderTest(
          slug: 'gg_version',
          manifestFile: 'pubspec.yaml',
        );
        expect(a, b);
      });
    });

    group('generated dart output', () {
      late Directory tmp;

      setUp(() async {
        tmp = await Directory.systemTemp.createTemp('version_file_spec');
      });

      tearDown(() async {
        await tmp.delete(recursive: true);
      });

      test('should be function free so gg_test exempts it from coverage', () {
        // gg_test skips the untested-file check when `hasFunctions` is false.
        // These are gg_test's own predicates, kept in sync deliberately: any
        // `(...)` followed by `{` or `=>` would flip them and turn the
        // generated file into a hard `tests` failure.
        final functionRegExp = RegExp(
          r'\b(?:[a-zA-Z_]\w*\s+)?'
          r'(?:get|set)?'
          r'\s+'
          r'([a-zA-Z_]\w*)'
          r'\s*'
          r'\('
          r'[^)]*'
          r'\)'
          r'\s*'
          r'(?:\=\>|\{)',
          multiLine: true,
          dotAll: true,
        );
        final getSetRegExp = RegExp(
          r'\b(?:[a-zA-Z_]\w*\s+)?'
          r'(get|set)\s+'
          r'([a-zA-Z_]\w*)'
          r'(?:\s*\(\s*([a-zA-Z_]\w*\s+[a-zA-Z_]\w*)?\s*\))?'
          r'\s*'
          r'(?:\=>\s*[^;]*;|\{[^}]*\})',
          multiLine: true,
        );

        for (final spec in const [
          VersionFileSpec.dartSpec,
          VersionFileSpec.flutterSpec,
        ]) {
          final content = spec.renderSource(
            slug: 'gg_version',
            version: '4.5.0',
            packageName: 'gg_version',
          );
          expect(functionRegExp.hasMatch(content), isFalse, reason: content);
          expect(getSetRegExp.hasMatch(content), isFalse, reason: content);
        }
      });

      test('should already be dart format clean', () async {
        // `format` runs before `tests` in `gg can commit`, so a generated file
        // that is not format clean passes locally and fails only on CI.
        const spec = VersionFileSpec.dartSpec;
        final source = File('${tmp.path}/gg_version_version.dart');
        final mirror = File('${tmp.path}/gg_version_version_test.dart');

        await source.writeAsString(
          spec.renderSource(
            slug: 'gg_version',
            version: '4.5.0',
            packageName: 'gg_version',
          ),
        );
        await mirror.writeAsString(
          spec.renderTest(slug: 'gg_version', manifestFile: 'pubspec.yaml'),
        );

        final result = await Process.run('dart', [
          'format',
          '--output=none',
          '--set-exit-if-changed',
          source.path,
          mirror.path,
        ]);

        expect(
          result.exitCode,
          0,
          reason:
              'dart format would rewrite the generated output:\n'
              '${result.stdout}${result.stderr}',
        );
      });

      test('should analyze without issues', () async {
        // Covers public_member_api_docs, prefer_single_quotes,
        // lines_longer_than_80_chars and the strict analyzer modes.
        const spec = VersionFileSpec.dartSpec;
        final pkg = Directory('${tmp.path}/pkg')..createSync(recursive: true);
        Directory('${pkg.path}/lib/src').createSync(recursive: true);
        Directory('${pkg.path}/test').createSync(recursive: true);

        File('${pkg.path}/pubspec.yaml').writeAsStringSync(
          'name: gg_version\n'
          'version: 4.5.0\n'
          'environment:\n'
          "  sdk: '>=3.8.0 <4.0.0'\n",
        );
        File(
          '${pkg.path}/analysis_options.yaml',
        ).writeAsStringSync(File('analysis_options.yaml').readAsStringSync());
        spec
            .sourceFile(pkg, 'gg_version')
            .writeAsStringSync(
              spec.renderSource(
                slug: 'gg_version',
                version: '4.5.0',
                packageName: 'gg_version',
              ),
            );

        final result = await Process.run('dart', [
          'analyze',
          '--fatal-infos',
          '--fatal-warnings',
          spec.sourceFile(pkg, 'gg_version').path,
        ]);

        expect(
          result.exitCode,
          0,
          reason: 'analyze failed:\n${result.stdout}${result.stderr}',
        );
      });
    });
  });
}
