// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_lang/gg_lang.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_version/gg_version.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

// #############################################################################
/// Writes the package version into a generated source file.
///
/// Creates `lib/src/<slug>_version.dart` for Dart and Flutter packages and
/// `src/<slug>_version.ts` for TypeScript packages, plus a self-healing mirror
/// test that keeps the file in sync whenever the test suite runs.
///
/// A cross-language bridge gets both files, each named after its own manifest.
/// Projects without a manifest are skipped.
class WriteVersionFile extends DirCommand<void> {
  /// Constructor.
  WriteVersionFile({
    required super.ggLog,
    LanguageCatalog? catalog,
    super.name = 'write-version-file',
    super.description =
        'Writes the package version into a generated source file.',
  }) : _catalog = catalog;

  // ...........................................................................
  @override
  Future<void> get({required Directory directory, required GgLog ggLog}) async {
    await check(directory: directory);
    await apply(directory: directory, ggLog: ggLog);
  }

  // ...........................................................................
  /// Writes the version file and its mirror test, and returns every file that
  /// was created or changed.
  ///
  /// Pass [version] to write a specific version instead of the one currently
  /// in the manifest. The publish flow uses this so the generated file already
  /// carries the version being released.
  ///
  /// Files whose content is already correct are left untouched, so calling this
  /// repeatedly does not churn the working tree. The mirror test is only
  /// rewritten when it is missing or does not carry [versionFileMarker] — that
  /// is what distinguishes a real generated test from the boilerplate stub
  /// `gg_test` plants for any `lib/src` file without a test.
  Future<List<File>> apply({
    required Directory directory,
    required GgLog ggLog,
    String? version,
  }) async {
    await check(directory: directory);

    final type = checkProjectType(directory);
    if (type == ProjectType.none) {
      ggLog('No manifest found - no version file is written.');
      return [];
    }

    final catalog = _catalog ?? await LanguageCatalog.load();
    final written = <File>[];

    // A bridge publishes as TypeScript but its Dart side must stay in
    // lock-step, so both languages get their own version file. The two
    // manifests may carry different package names.
    final types = <ProjectType>[
      type,
      if (isBridgeProject(directory)) detectProjectType(directory),
    ];

    for (final projectType in types) {
      // ProjectType.none is the only type without a spec, and it returned
      // above. A bridge's Dart side is always dart or flutter.
      final spec = VersionFileSpec.forProjectType(projectType)!;

      written.addAll(
        await _writeFor(
          directory: directory,
          projectType: projectType,
          spec: spec,
          catalog: catalog,
          version: version,
          ggLog: ggLog,
        ),
      );
    }

    return written;
  }

  // ######################
  // Private
  // ######################

  final LanguageCatalog? _catalog;

  // ...........................................................................
  Future<List<File>> _writeFor({
    required Directory directory,
    required ProjectType projectType,
    required VersionFileSpec spec,
    required LanguageCatalog catalog,
    required String? version,
    required GgLog ggLog,
  }) async {
    final manifestSpec = catalog.spec(projectType).manifest;
    final manifest = Manifest(directory: directory, spec: manifestSpec);

    // Without a name there is no slug and therefore no file to write. This is
    // a degenerate manifest rather than an error: the generator also runs as a
    // side effect of other commands and must never break its host.
    final String packageName;
    try {
      packageName = await manifest.readName();
    } on ManifestException {
      ggLog('No "name" in ${manifestSpec.file} - no version file is written.');
      return [];
    }

    final resolvedVersion = version ?? await manifest.readVersionString();
    if (resolvedVersion == null) {
      throw Exception('"version:" not found in ${manifestSpec.file}');
    }

    final slug = versionFileSlug(packageName);
    final written = <File>[];

    // The version file - rewritten whenever the version literal changed.
    final sourceFile = spec.sourceFile(directory, slug);
    final source = spec.renderSource(
      slug: slug,
      version: resolvedVersion,
      packageName: packageName,
    );
    if (await _writeIfChanged(sourceFile, source)) {
      written.add(sourceFile);
      ggLog('Wrote ${spec.sourcePath(slug)}');
    }

    // The mirror test - only when missing or not generated by us.
    final testFile = spec.testFile(directory, slug);
    final hasMarker =
        await testFile.exists() &&
        (await testFile.readAsString()).contains(versionFileMarker);

    if (!hasMarker) {
      final test = spec.renderTest(slug: slug, manifestFile: manifestSpec.file);
      await _writeIfChanged(testFile, test);
      written.add(testFile);
      ggLog('Wrote ${spec.testPath(slug)}');

      if (!spec.isDart) {
        final typesFile = await _ensureNodeTypes(directory, ggLog);
        if (typesFile != null) {
          written.add(typesFile);
        }
      }
    }

    return written;
  }

  // ...........................................................................
  /// Writes [content] to [file] unless it already holds exactly that content.
  ///
  /// Returns whether anything was written. A single write, never
  /// delete-then-write, so a concurrent reader never observes a missing file.
  Future<bool> _writeIfChanged(File file, String content) async {
    if (await file.exists() && await file.readAsString() == content) {
      return false;
    }

    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    return true;
  }

  // ...........................................................................
  /// Adds `@types/node` to the TypeScript package's dev dependencies.
  ///
  /// The generated mirror test reads and writes the version file through
  /// `node:fs`, which does not type check without those types. Returns the
  /// manifest when it was changed, null when the entry was already there.
  Future<File?> _ensureNodeTypes(Directory directory, GgLog ggLog) async {
    final file = File('${directory.path}/package.json');
    if (!await file.exists()) {
      return null;
    }

    final json = jsonDecode(await file.readAsString());
    if (json is! Map<String, dynamic>) {
      return null;
    }

    final devDependencies = json['devDependencies'];
    final deps = devDependencies is Map<String, dynamic>
        ? devDependencies
        : <String, dynamic>{};

    if (deps.containsKey('@types/node')) {
      return null;
    }

    deps['@types/node'] = '^22.0.0';
    json['devDependencies'] = deps;

    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(json)}\n');
    ggLog('Added "@types/node" to package.json');

    return file;
  }
}

// .............................................................................
/// Mock class for WriteVersionFile
class MockWriteVersionFile extends mocktail.Mock implements WriteVersionFile {}
