// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_git/gg_git.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_version/gg_version.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

// #############################################################################
/// Provides "ggGit has-version-tag <dir>" command
class AddVersionTag extends GgGitBase<void> {
  /// Constructor
  AddVersionTag({
    required super.ggLog,
    super.processWrapper,
  }) : super(
          name: 'add-version-tag',
          description: 'Reads version from pubspec.yaml and adds it as git tag',
        );

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    String? lastLog;

    await add(
      directory: directory,
      ggLog: (msg) {
        lastLog = msg;
      },
    );

    ggLog(lastLog ?? 'Version tag added.');
  }

  // ...........................................................................
  /// Returns true if everything in the directory is pushed.
  Future<bool> add({
    required GgLog ggLog,
    required Directory directory,
  }) async {
    // Throw if not everything is commited
    final isCommited = await IsCommitted(
      ggLog: ggLog,
      processWrapper: processWrapper,
    ).get(directory: directory, ggLog: ggLog);

    if (!isCommited) {
      throw StateError('Not everything is commited.');
    }

    final versions = await AllVersions(
      ggLog: ggLog,
      processWrapper: processWrapper,
    ).get(
      ggLog: ggLog,
      directory: directory,
    );

    // If version is already set, do nothing
    final pubspecVersion = versions.pubspec;
    final changeLogVersion = versions.changeLog;
    final tagVersion = versions.gitHead;
    final latestVersion = versions.gitLatest;

    if (pubspecVersion == changeLogVersion && pubspecVersion == tagVersion) {
      ggLog('Version already set.');
      return true;
    }

    // If version in pubspec is not equal to version in change log, throw
    if (pubspecVersion != changeLogVersion) {
      throw Exception(
        'Version in pubspec.yaml is not equal version in CHANGELOG.md.',
      );
    }

    // If head already has a version tag, throw
    if (tagVersion != null) {
      throw Exception('Head has already a version tag.');
    }

    // If version in pubspec is smaller latest version, throw
    if (latestVersion != null && pubspecVersion <= latestVersion) {
      throw Exception(
        'Version in pubspec.yaml and CHANGELOG.md must be greater '
        '${latestVersion.toString()}',
      );
    }

    // Create a tag and push it
    final version = pubspecVersion.toString();
    final result = await processWrapper.run(
      'git',
      ['tag', '-a', version, '-m', 'Version $version'],
      workingDirectory: directory.path,
    );

    if (result.exitCode == 0) {
      ggLog('Tag $version added.');
      return true;
    } else {
      throw Exception('Could not add tag $version: ${result.stderr}');
    }
  }
}

// .............................................................................
/// Mock class for AddVersionTag
class MockAddVersionTag extends mocktail.Mock implements AddVersionTag {}
