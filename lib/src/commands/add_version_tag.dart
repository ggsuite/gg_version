// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_git/gg_git.dart';
import 'package:gg_version/gg_version.dart';

// #############################################################################
/// Provides "ggGit has-version-tag <dir>" command
class AddVersionTag extends GgGitBase {
  /// Constructor
  AddVersionTag({
    required super.log,
    super.processWrapper,
    super.inputDir,
  });

  // ...........................................................................
  @override
  final name = 'add-version-tag';
  @override
  final description = 'Reads version from pubspec.yaml and adds it as git tag';

  // ...........................................................................
  @override
  Future<void> run() async {
    await super.run();

    String? lastLog;

    await add(
      log: (msg) {
        lastLog = msg;
        log(msg);
      },
    );

    log(lastLog ?? 'Version tag added.');
  }

  // ...........................................................................
  /// Returns true if everything in the directory is pushed.
  Future<bool> add({
    void Function(String)? log,
  }) async {
    log ??= this.log; //coverage:ignore-line

    // Throw if not everything is commited
    final isCommited = await IsCommitted(
      log: log,
      processWrapper: processWrapper,
      inputDir: inputDir,
    ).get();

    if (!isCommited) {
      throw StateError('Not everything is commited.');
    }

    final versions = await AllVersions(
      log: log,
      processWrapper: processWrapper,
      inputDir: inputDir,
    ).get(
      log: log,
    );

    // If version is already set, do nothing
    final pubspecVersion = versions.pubspec;
    final changeLogVersion = versions.changeLog;
    final tagVersion = versions.gitHead;
    final latestVersion = versions.gitLatest;

    if (pubspecVersion == changeLogVersion && pubspecVersion == tagVersion) {
      log('Version already set.');
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
      workingDirectory: inputDir.path,
    );

    if (result.exitCode == 0) {
      log('Tag $version added.');
      return true;
    } else {
      throw Exception('Could not add tag $version: ${result.stderr}');
    }
  }
}
