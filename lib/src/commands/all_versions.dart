// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_version/gg_version.dart';
import 'package:pub_semver/pub_semver.dart';

// #############################################################################
/// Provides "ggGit has-consistent-version <dir>" command
class AllVersions extends GgGitBase {
  /// Constructor
  AllVersions({
    required super.log,
    super.processWrapper,
    super.inputDir,
  });

  // ...........................................................................
  @override
  final name = 'all-versions';
  @override
  final description =
      'Returns the version of pubspec.yaml, README.md as well git head tag. ';

  // ...........................................................................
  @override
  Future<void> run() async {
    await super.run();

    final messages = <String>[];

    try {
      final v = await get(
        log: messages.add,
      );

      log('pubspec: ${v.pubspec}');
      log('changelog: ${v.changeLog}');
      log('git head: ${v.gitHead ?? '-'}');
      log('git latest: ${v.gitLatest ?? '-'}');
    } catch (e) {
      throw Exception('$red$e$reset');
    }
  }

  // ...........................................................................
  /// Returns the consistent version or null if not consistent.
  Future<
      ({
        Version pubspec,
        Version changeLog,
        Version? gitHead,
        Version? gitLatest,
      })> get({
    void Function(String message)? log,
  }) async {
    log ??= this.log; //coverage:ignore-line
    final isCommitted = await IsCommitted(
      log: log,
      processWrapper: processWrapper,
      inputDir: inputDir,
    ).get(
      log: log,
    );

    final pubspecVersion = await FromPubspec(
      log: log,
      inputDir: inputDir,
    ).fromDirectory();
    final changelogVersion = await FromChangelog(
      log: log,
      inputDir: inputDir,
    ).fromDirectory();

    final gitHeadVersion = isCommitted
        ? await FromGit(
            log: log,
            inputDir: inputDir,
          ).fromHead(
            log: log,
          )
        : null;

    final gitLatestVersion = gitHeadVersion ??
        await FromGit(
          processWrapper: processWrapper,
          log: log,
          inputDir: inputDir,
        ).latest();

    return (
      pubspec: pubspecVersion,
      changeLog: changelogVersion,
      gitHead: gitHeadVersion,
      gitLatest: gitLatestVersion,
    );
  }
}
