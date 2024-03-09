// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:gg_version/gg_version.dart';
import 'package:pub_semver/pub_semver.dart';

// #############################################################################
/// Provides "ggGit has-consistent-version <dir>" command
class CheckVersions extends GgGitBase {
  /// Constructor
  CheckVersions({
    required super.log,
    super.processWrapper,
  });

  // ...........................................................................
  @override
  final name = 'check-versions';
  @override
  final description = 'Checks if pubspec.yaml, README.md as well git head tag '
      'have the same version. '
      'Reports an error when this version is not consistent.';

  // ...........................................................................
  @override
  Future<void> run() async {
    await super.run();

    final messages = <String>[];

    final printer = GgStatusPrinter<Version>(
      message: 'Versions are consistent.',
      log: log,
    );

    try {
      await printer.logTask(
        task: () => ConsistentVersion.get(
          directory: inputDir,
          processWrapper: processWrapper,
          log: messages.add,
          dirName: inputDirName,
        ),
        success: (success) => true,
      );
    } catch (e) {
      throw Exception('$brightBlack$e$reset');
    }
  }
}
