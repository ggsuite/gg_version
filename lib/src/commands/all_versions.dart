// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_version/gg_version.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

// #############################################################################
/// Provides "ggGit has-consistent-version <dir>" command
class AllVersions extends GgGitBase {
  /// Constructor
  AllVersions({
    required super.log,
    super.processWrapper,
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
      final v = await AllVersions.get(
        directory: inputDir,
        processWrapper: processWrapper,
        log: messages.add,
        dirName: inputDirName,
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
  static Future<
      ({
        Version pubspec,
        Version changeLog,
        Version? gitHead,
        Version? gitLatest,
      })> get({
    required Directory directory,
    GgProcessWrapper processWrapper = const GgProcessWrapper(),
    required void Function(String message) log,
    String? dirName,
  }) async {
    dirName ??= basename(canonicalize(directory.path));

    final isCommitted = await IsCommitted.get(
      directory: directory,
      processWrapper: processWrapper,
    );

    final d = directory;
    final pubspecVersion = await FromPubspec.fromDirectory(directory: d);
    final changelogVersion = await FromChangelog.fromDirectory(directory: d);

    final gitHeadVersion = isCommitted
        ? await FromGit.fromHead(
            directory: directory,
            processWrapper: processWrapper,
            log: log,
          )
        : null;

    final gitLatestVersion = gitHeadVersion ??
        await FromGit.latest(
          directory: directory,
          processWrapper: processWrapper,
          log: log,
        );

    return (
      pubspec: pubspecVersion,
      changeLog: changelogVersion,
      gitHead: gitHeadVersion,
      gitLatest: gitLatestVersion,
    );
  }
}
