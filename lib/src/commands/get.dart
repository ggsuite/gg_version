// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_git/gg_git.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_version/gg_version.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

// #############################################################################
/// Provides "ggGit has-consistent-version <dir>" command
class Get extends GgGitBase {
  /// Constructor
  Get({
    required super.log,
    super.processWrapper,
  });

  // ...........................................................................
  @override
  final name = 'get';
  @override
  final description = 'Returns version of the current head revision '
      'collected from pubspec.yaml, README.md as well git head tag. '
      'Reports when these versions are not consistent.';

  // ...........................................................................
  @override
  Future<void> run() async {
    await super.run();

    final version = await consistantVersion(
      directory: directory,
      processWrapper: processWrapper,
      log: log,
      dirName: directoryName,
    );

    log(version.toString());
  }

  // ...........................................................................
  /// Returns the consistent version or null if not consistent.
  static Future<Version> consistantVersion({
    required String directory,
    GgProcessWrapper processWrapper = const GgProcessWrapper(),
    required void Function(String message) log,
    String? dirName,
  }) async {
    final result = await versions(
      directory: directory,
      processWrapper: processWrapper,
      log: log,
    );

    if (result.gitHead == null) {
      throw Exception('Current state has no git version tag.');
    }

    if (result.pubspec == result.changeLog &&
        result.gitHead == result.changeLog) {
      return result.pubspec;
    } else {
      var message = 'Versions are not consistent: ';
      message += '- pubspec: ${result.pubspec}, ';
      message += '- changeLog: ${result.changeLog}, ';
      message += '- gitHead: ${result.gitHead}';

      throw Exception(message);
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
      })> versions({
    required String directory,
    GgProcessWrapper processWrapper = const GgProcessWrapper(),
    required void Function(String message) log,
    String? dirName,
  }) async {
    dirName ??= basename(canonicalize(directory));

    final isCommitted = await IsCommited.isCommited(
      directory: directory,
      processWrapper: processWrapper,
    );

    if (!isCommitted) {
      throw Exception('Please commit everything in "$dirName".');
    }

    final d = directory;
    final pubspecVersion = await FromPubspec.fromDirectory(directory: d);
    final changelogVersion = await FromChangelog.fromDirectory(directory: d);

    final gitHeadVersion = await FromGit.fromHead(
      directory: directory,
      processWrapper: processWrapper,
      log: log,
    );

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
