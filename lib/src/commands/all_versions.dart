// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_version/gg_version.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

// #############################################################################
/// Provides "ggGit has-consistent-version <dir>" command
class AllVersions extends GgGitBase<void> {
  /// Constructor
  AllVersions({
    required super.ggLog,
    super.processWrapper,
  }) : super(
          name: 'all-versions',
          description: 'Returns the version of pubspec.yaml, README.md '
              'and git head tag. ',
        );

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    final messages = <String>[];

    try {
      final v = await get(
        ggLog: messages.add,
        directory: directory,
      );

      ggLog('pubspec: ${v.pubspec}');
      ggLog('changelog: ${v.changeLog}');
      ggLog('git head: ${v.gitHead ?? '-'}');
      ggLog('git latest: ${v.gitLatest ?? '-'}');
    } catch (e) {
      throw Exception(red(e.toString()));
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
    required GgLog ggLog,
    required Directory directory,
    bool ignoreUncommitted = false,
  }) async {
    final isCommitted = ignoreUncommitted ||
        await IsCommitted(
          ggLog: ggLog,
          processWrapper: processWrapper,
        ).get(
          ggLog: ggLog,
          directory: directory,
        );

    final pubspecVersion = await FromPubspec(
      ggLog: ggLog,
    ).fromDirectory(
      directory: directory,
    );
    final changelogVersion = await FromChangelog(
      ggLog: ggLog,
    ).fromDirectory(
      directory: directory,
    );

    final gitHeadVersion = isCommitted
        ? await FromGit(
            ggLog: ggLog,
          ).fromHead(
            ggLog: ggLog,
            directory: directory,
          )
        : null;

    final gitLatestVersion = gitHeadVersion ??
        await FromGit(
          processWrapper: processWrapper,
          ggLog: ggLog,
        ).latest(
          directory: directory,
          ggLog: ggLog,
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
