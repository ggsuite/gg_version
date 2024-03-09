// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_version/src/commands/all_versions.dart';
import 'package:pub_semver/pub_semver.dart';

// #############################################################################
/// Provides "ggGit has-consistent-version <dir>" command
class ConsistentVersion extends GgGitBase {
  /// Constructor
  ConsistentVersion({
    required super.log,
    super.processWrapper,
  });

  // ...........................................................................
  @override
  final name = 'consistent-version';
  @override
  final description = 'Returns version of the current head revision '
      'collected from pubspec.yaml, README.md as well git head tag. '
      'Reports an error when this version is not consistent.';

  // ...........................................................................
  @override
  Future<void> run() async {
    await super.run();

    final messages = <String>[];

    try {
      final version = await get(
        directory: inputDir,
        processWrapper: processWrapper,
        log: messages.add,
        dirName: inputDirName,
      );
      log(version.toString());
    } catch (e) {
      throw Exception('$red$e$reset');
    }
  }

  // ...........................................................................
  /// Returns the consistent version or null if not consistent.
  static Future<Version> get({
    required Directory directory,
    GgProcessWrapper processWrapper = const GgProcessWrapper(),
    required void Function(String message) log,
    String? dirName,
  }) async {
    final result = await AllVersions.get(
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
}
