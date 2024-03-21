// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:gg_version/gg_version.dart';

// #############################################################################
/// Provides "ggGit has-consistent-version <dir>" command
class IsVersioned extends GgGitBase {
  /// Constructor
  IsVersioned({
    required super.log,
    super.processWrapper,
    super.inputDir,
  });

  // ...........................................................................
  @override
  final name = 'is-versioned';
  @override
  final description = 'Checks if pubspec.yaml, README.md and git head tag '
      'have same version. ';

  // ...........................................................................
  @override
  Future<void> run() async {
    await super.run();

    final messages = <String>[];

    final printer = GgStatusPrinter<bool>(
      message: 'Versions are consistent.',
      log: log,
    );

    final isConsistent = await printer.logTask(
      task: () => IsVersioned(
        log: log,
        processWrapper: processWrapper,
        inputDir: inputDir,
      ).get(
        log: messages.add,
        dirName: inputDirName,
      ),
      success: (success) => success,
    );

    if (!isConsistent) {
      throw Exception('$brightBlack${messages.join('\n')}$reset');
    }
  }

  // ...........................................................................
  /// Returns true if pubspect.yaml, README.md as well git show the same version
  Future<bool> get({
    String? dirName,
    required void Function(String) log,
  }) async {
    try {
      final version = await ConsistentVersion(
        log: log,
        processWrapper: processWrapper,
        inputDir: inputDir,
      ).get(
        log: log,
      );
      log(version.toString());
      return true;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }
}
