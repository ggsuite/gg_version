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
class ConsistentVersion extends GgGitBase<void> {
  /// Constructor
  ConsistentVersion({
    required super.log,
    super.processWrapper,
  }) : super(
          name: 'consistent-version',
          description:
              'Returns version of pubspec.yaml, README.md and git tag.',
        );

  // ...........................................................................
  @override
  Future<void> run({Directory? directory, VersionType? ignoreVersion}) async {
    final inputDir = dir(directory);

    final messages = <String>[];

    try {
      final version = await get(
        log: messages.add,
        directory: inputDir,
        ignoreVersion: ignoreVersion,
      );
      log(version.toString());
    } catch (e) {
      throw Exception('$red$e$reset');
    }
  }

  // ...........................................................................
  /// Returns the consistent version or null if not consistent.
  Future<Version> get({
    void Function(String message)? log,
    required Directory directory,
    VersionType? ignoreVersion,
  }) async {
    final result = await AllVersions(
      log: log ?? this.log,
      processWrapper: processWrapper,
    ).get(
      log: log,
      directory: directory,
    );

    if (result.gitHead == null) {
      throw Exception('Current state has no git version tag.');
    }

    final ignorePubspec = ignoreVersion == VersionType.pubspec;
    final ignoreChangeLog = ignoreVersion == VersionType.changeLog;
    final ignoreGitHead = ignoreVersion == VersionType.gitHead;

    var versions = [
      if (!ignorePubspec) result.pubspec,
      if (!ignoreChangeLog) result.changeLog,
      if (!ignoreGitHead) result.gitHead,
    ];

    bool allVersionsAreTheSame = versions.toSet().length == 1;

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
