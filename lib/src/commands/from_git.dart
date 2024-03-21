// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_git/gg_git.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

// #############################################################################
/// Provides "ggGit current-version-tag <dir>" command
class FromGit extends GgGitBase<void> {
  /// Constructor
  FromGit({
    required super.log,
    super.processWrapper,
  }) : super(
          name: 'from-git',
          description: 'Returns the version tag of the latest state '
              'or nothing if not tagged',
        ) {
    _addArgs();
  }

  // ...........................................................................
  @override
  Future<void> run({Directory? directory}) async {
    final inputDir = dir(directory);

    final headOnly = argResults!['head-only'] as bool;

    if (headOnly) {
      final result = await fromHead(
        log: super.log,
        directory: inputDir,
      );

      log(result?.toString() ?? 'No version tag found in head.');
    } else {
      final result = await latest(
        log: super.log,
        directory: inputDir,
      );

      log(result?.toString() ?? 'No version tag found.');
    }
  }

  // ...........................................................................
  /// Returns true if everything in the directory is pushed.
  Future<Version?> fromHead({
    void Function(String message)? log,
    required Directory directory,
  }) async {
    log ??= this.log; //coverage:ignore-line

    await check(directory: directory);

    final headTags = await GetTags(
      log: log,
      processWrapper: processWrapper,
    ).fromHead(
      log: log,
      directory: directory,
    );

    final versions = _getVersions(headTags);
    if (versions.length > 1) {
      throw StateError(
        'There are multiple version tags for the latest revision.\n'
        'Please remove all but one.',
      );
    }

    return versions.firstOrNull;
  }

  // ...........................................................................
  /// Returns true if everything in the directory is pushed.
  Future<Version?> latest({
    void Function(String message)? log,
    required Directory directory,
  }) async {
    log ??= this.log; //coverage:ignore-line

    await check(directory: directory);

    final tags = await GetTags(
      log: log,
      processWrapper: processWrapper,
    ).all(
      log: log,
      directory: directory,
    );

    final versions = _getVersions(tags);
    return versions.firstOrNull;
  }

  // ...........................................................................
  static List<Version> _getVersions(List<String> tags) {
    final versions = <Version>[];
    for (final tag in tags) {
      try {
        final version = Version.parse(tag);
        versions.add(version);
      } catch (e) {
        // ignore
      }
    }
    return versions;
  }

  // ...........................................................................
  void _addArgs() {
    argParser.addFlag(
      'head-only',
      abbr: 'l',
      help: 'Get only version assigned to head revision',
      defaultsTo: false,
    );
  }
}

// .............................................................................
/// Mock class for FromGit
class MockFromGit extends mocktail.Mock implements FromGit {}
