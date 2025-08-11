// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:gg_version/gg_version.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

// #############################################################################
/// Provides "ggGit has-consistent-version dir" command
class IsVersioned extends GgGitBase<void> {
  /// Constructor
  IsVersioned({
    required super.ggLog,
    super.processWrapper,
  }) : super(
          name: 'is-versioned',
          description: 'Checks if pubspec.yaml, README.md and git head tag '
              'have same version. ',
        ) {
    _addArgs();
  }

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
    VersionType? ignoreVersion,
  }) async {
    ignoreVersion ??= _ignoreVersionFromArgs;

    final messages = <String>[];

    final printer = GgStatusPrinter<bool>(
      message: 'Versions are consistent.',
      ggLog: ggLog,
    );

    final isConsistent = await printer.logTask(
      task: () => get(
        ggLog: messages.add,
        directory: directory,
        ignoreVersion: ignoreVersion,
      ),
      success: (success) => success,
    );

    if (!isConsistent) {
      throw Exception(brightBlack(messages.join('\n')));
    }
  }

  // ...........................................................................
  /// Returns true if pubspect.yaml, README.md as well git show the same version
  @override
  Future<bool> get({
    required Directory directory,
    required GgLog ggLog,
    VersionType? ignoreVersion,
  }) async {
    try {
      final version = await ConsistentVersion(
        ggLog: ggLog,
        processWrapper: processWrapper,
      ).get(
        directory: directory,
        ggLog: ggLog,
        ignoreVersion: ignoreVersion,
      );
      ggLog(version.toString());
      return true;
    } catch (e) {
      ggLog(e.toString());
      return false;
    }
  }

  // ...........................................................................
  VersionType? get _ignoreVersionFromArgs {
    final ignoreVersionFromArgsStr = argResults?['ignore-version'] as String?;
    return ignoreVersionFromArgsStr == null
        ? null
        : VersionType.values.byName(ignoreVersionFromArgsStr);
  }

  // ...........................................................................
  void _addArgs() {
    argParser.addOption(
      'ignore-version',
      abbr: 'g',
      help: 'Ignore the specified version.',
      allowed: VersionType.values.map((e) => e.name),
      mandatory: false,
    );
  }
}

// .............................................................................
/// Mock class for IsVersioned
class MockIsVersioned extends mocktail.Mock implements IsVersioned {}
