// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_lang/gg_lang.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:gg_version/gg_version.dart';
import 'package:mocktail/mocktail.dart' as mocktail;
import 'package:pub_semver/pub_semver.dart';

// .............................................................................
/// Checks that CHANGELOG.md has no released section above the manifest
/// version.
///
/// The manifest (`pubspec.yaml` / `package.json`) carries the version that
/// was published last; the release bumps it and turns `## Unreleased` into
/// the new section. A section that is already ahead of the manifest was
/// written by hand — it would be shipped under a version the release never
/// produces and would shadow every later entry. `## Unreleased` is what the
/// pending changes belong under, so it is always allowed.
class NoFutureVersions extends DirCommand<bool> {
  /// Constructor
  NoFutureVersions({
    required super.ggLog,
    FromPubspec? fromPubspec,
    FromChangelog? fromChangelog,
  }) : _fromPubspec = fromPubspec ?? FromPubspec(ggLog: ggLog),
       _fromChangelog = fromChangelog ?? FromChangelog(ggLog: ggLog),
       super(
         name: 'no-future-versions',
         description:
             'Checks that CHANGELOG.md has no version above the one '
             'in pubspec.yaml / package.json.',
       );

  // ...........................................................................
  @override
  Future<bool> exec({
    required Directory directory,
    required GgLog ggLog,
    Map<String, dynamic> options = const {},
  }) async {
    final messages = <String>[];

    final printer = GgStatusPrinter<bool>(
      message: 'CHANGELOG.md has no version above the manifest.',
      ggLog: ggLog,
      dark: true,
    );

    final ok = await printer.logTask(
      task: () => get(ggLog: messages.add, directory: directory),
      success: (success) => success,
    );

    if (!ok) {
      throw Exception(brightBlack(messages.join('\n')));
    }

    return ok;
  }

  // ...........................................................................
  /// Returns true when every released section of CHANGELOG.md is at or
  /// below the manifest version. Logs the offending sections otherwise.
  ///
  /// A folder without a manifest tracks its version via git tags only, and
  /// a package without a CHANGELOG.md has nothing to be ahead — both pass.
  @override
  Future<bool> get({required Directory directory, required GgLog ggLog}) async {
    if (detectProjectType(directory) == ProjectType.none) {
      ggLog(
        'No manifest — the version is tracked via git tags only. '
        'Check skipped.',
      );
      return true;
    }

    final changelog = File('${directory.path}/CHANGELOG.md');
    if (!changelog.existsSync()) {
      ggLog('No CHANGELOG.md. Check skipped.');
      return true;
    }

    final manifestVersion = await _fromPubspec.fromDirectory(
      directory: directory,
    );
    final changelogVersions = await _fromChangelog.allFromDirectory(
      directory: directory,
    );

    final ahead = changelogVersions
        .where((version) => version > manifestVersion)
        .toList();

    if (ahead.isEmpty) {
      ggLog('CHANGELOG.md has no version above $manifestVersion.');
      return true;
    }

    ggLog(_message(ahead: ahead, manifestVersion: manifestVersion));
    return false;
  }

  // ######################
  // Private
  // ######################

  final FromPubspec _fromPubspec;
  final FromChangelog _fromChangelog;

  // ...........................................................................
  String _message({
    required List<Version> ahead,
    required Version manifestVersion,
  }) {
    final versions = ahead.map((v) => v.toString()).join(', ');
    final sections = ahead.length == 1 ? 'a version' : 'versions';
    return 'CHANGELOG.md lists $sections above the manifest version '
        '$manifestVersion: $versions. '
        'Move the entries under "## Unreleased" or remove the section — '
        'the release writes the new version itself.';
  }
}

// .............................................................................
/// Mock class for NoFutureVersions
class MockNoFutureVersions extends mocktail.Mock implements NoFutureVersions {}
