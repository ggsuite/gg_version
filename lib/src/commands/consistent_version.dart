// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_version/src/commands/all_versions.dart';
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
  Future<void> run({Directory? directory}) async {
    final inputDir = dir(directory);

    final messages = <String>[];

    try {
      final version = await get(
        log: messages.add,
        directory: inputDir,
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
}

// .............................................................................
/// Mock class for ConsistentVersion
class MockConsistentVersion extends mocktail.Mock
    implements ConsistentVersion {}
