// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_git/gg_git.dart';
import 'package:gg_log/gg_log.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

// #############################################################################
/// Provides "ggGit current-version-tag dir" command
class FromGit extends GgGitBase<Version?> {
  /// Constructor
  FromGit({
    required super.ggLog,
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
  Future<Version?> get({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    final headOnly = argResults!['head-only'] as bool;

    Version? result;

    if (headOnly) {
      result = await fromHead(
        ggLog: super.ggLog,
        directory: directory,
      );

      ggLog(result?.toString() ?? 'No version tag found in head.');
    } else {
      result = await latest(
        ggLog: super.ggLog,
        directory: directory,
      );

      ggLog(result?.toString() ?? 'No version tag found.');
    }
    return result;
  }

  // ...........................................................................
  /// Returns true if everything in the directory is pushed.
  Future<Version?> fromHead({
    required GgLog ggLog,
    required Directory directory,
  }) async {
    await check(directory: directory);

    final headTags = await GetTags(
      ggLog: ggLog,
      processWrapper: processWrapper,
    ).fromHead(
      ggLog: ggLog,
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
    required GgLog ggLog,
    required Directory directory,
  }) async {
    await check(directory: directory);

    final tags = await GetTags(
      ggLog: ggLog,
      processWrapper: processWrapper,
    ).all(
      ggLog: ggLog,
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
