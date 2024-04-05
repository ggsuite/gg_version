// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_log/gg_log.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

// #############################################################################
/// Provides "ggGit current-version-tag <dir>" command
class FromChangelog extends DirCommand<void> {
  /// Constructor
  FromChangelog({
    required super.ggLog,
  }) : super(
          name: 'from-changelog',
          description: 'Returns the version found in CHANGELOG.md',
        );

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    final result = await fromDirectory(directory: directory);

    ggLog(result.toString());
  }

  // ...........................................................................
  /// Returns true if everything in the directory is pushed.
  Future<Version> fromDirectory({required Directory directory}) async {
    await check(directory: directory);
    final pubspec = File('${directory.path}/CHANGELOG.md');
    final dirName = basename(canonicalize(directory.path));

    if (!pubspec.existsSync()) {
      throw Exception('File "$dirName/CHANGELOG.md" does not exist.');
    }

    return fromString(content: pubspec.readAsStringSync());
  }

  // ...........................................................................
  /// Parses version from pubspec.yaml
  Version fromString({
    required String content,
  }) {
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.startsWith('## ')) {
        if (line.contains('Unreleased')) {
          continue;
        }

        final regExp =
            RegExp(r'##\s+\[?(\d+\.\d+\.\d+)\]?', caseSensitive: true);
        final match = regExp.firstMatch(line);
        final version = match?.group(1);
        if (version != null) {
          return Version.parse(version);
        }
      }
    }

    throw Exception('Could not find version in "CHANGELOG.md".');
  }
}

// .............................................................................
/// Mock class for FromChangelog
class MockFromChangelog extends mocktail.Mock implements FromChangelog {}
