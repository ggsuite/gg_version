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
/// Provides "ggGit has-consistent-version dir" command
class ConsistentVersion extends GgGitBase<void> {
  /// Constructor
  ConsistentVersion({
    required super.ggLog,
    super.processWrapper,
  }) : super(
          name: 'consistent-version',
          description:
              'Returns version of pubspec.yaml, README.md and git tag.',
        );

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
    VersionType? ignoreVersion,
  }) async {
    final messages = <String>[];

    try {
      final version = await get(
        ggLog: messages.add,
        directory: directory,
        ignoreVersion: ignoreVersion,
      );
      ggLog(version.toString());
    } catch (e) {
      throw Exception(red(e));
    }
  }

  // ...........................................................................
  /// Returns the consistent version or null if not consistent.
  @override
  Future<Version> get({
    required GgLog ggLog,
    required Directory directory,
    VersionType? ignoreVersion,
  }) async {
    final result = await AllVersions(
      ggLog: ggLog,
      processWrapper: processWrapper,
    ).get(
      ggLog: ggLog,
      directory: directory,
    );

    if (result.gitHead == null) {
      throw Exception('Current state has no git version tag.');
    }

    final ignorePubspec = ignoreVersion == VersionType.pubspec;
    final ignoreChangeLog = ignoreVersion == VersionType.changeLog;
    final ignoreGitHead = ignoreVersion == VersionType.gitHead;

    final versions = [
      if (!ignorePubspec) result.pubspec,
      if (!ignoreChangeLog) result.changeLog,
      if (!ignoreGitHead) result.gitHead,
    ];

    final allVersionsAreTheSame = versions.toSet().length == 1;

    if (allVersionsAreTheSame) {
      return versions.first!;
    } else {
      var message = 'Versions are not consistent: ';
      message += '- pubspec: ${result.pubspec}, ';
      message += '- changeLog: ${result.changeLog}, ';
      message += '- gitHead: ${result.gitHead}';

      throw Exception(message);
    }
  }
}

// .............................................................................
/// Mock class for ConsistentVersion
class MockConsistentVersion extends mocktail.Mock
    implements ConsistentVersion {}
