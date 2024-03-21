// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_version/gg_version.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

// #############################################################################
/// Provides "ggGit has-consistent-version <dir>" command
class AllVersions extends GgGitBase<void> {
  /// Constructor
  AllVersions({
    required super.log,
    super.processWrapper,
  }) : super(
          name: 'all-versions',
          description: 'Returns the version of pubspec.yaml, README.md '
              'and git head tag. ',
        );

  // ...........................................................................
  @override
  Future<void> run({Directory? directory}) async {
    final inputDir = dir(directory);

    final messages = <String>[];

    try {
      final v = await get(
        log: messages.add,
        directory: inputDir,
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
    required Directory directory,
  }) async {
    log ??= this.log; //coverage:ignore-line
    final isCommitted = await IsCommitted(
      log: log,
      processWrapper: processWrapper,
    ).get(
      log: log,
      directory: directory,
    );

    final pubspecVersion = await FromPubspec(
      log: log,
    ).fromDirectory(
      directory: directory,
    );
    final changelogVersion = await FromChangelog(
      log: log,
    ).fromDirectory(
      directory: directory,
    );

    final gitHeadVersion = isCommitted
        ? await FromGit(
            log: log,
          ).fromHead(
            log: log,
            directory: directory,
          )
        : null;

    final gitLatestVersion = gitHeadVersion ??
        await FromGit(
          processWrapper: processWrapper,
          log: log,
        ).latest(
          directory: directory,
        );

    return (
      pubspec: pubspecVersion,
      changeLog: changelogVersion,
      gitHead: gitHeadVersion,
      gitLatest: gitLatestVersion,
    );
  }
}

// .............................................................................
/// Mock class for AllVersions
class MockAllVersions extends mocktail.Mock implements AllVersions {}
