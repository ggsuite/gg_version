// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:gg_args/gg_args.dart';
import 'package:gg_log/gg_log.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

// #############################################################################
/// Provides "ggGit current-version-tag dir" command
class FromPubspec extends DirCommand<Version> {
  /// Constructor
  FromPubspec({
    required super.ggLog,
  }) : super(
          name: 'from-pubspec',
          description: 'Returns the version found in pubspec.yaml',
        );

  // ...........................................................................
  @override
  Future<Version> get({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    final result = await fromDirectory(directory: directory);
    ggLog(result.toString());
    return result;
  }

  // ...........................................................................
  /// Returns true if everything in the directory is pushed.
  Future<Version> fromDirectory({required Directory directory}) async {
    await check(directory: directory);
    final pubspec = File('${directory.path}/pubspec.yaml');
    final dirName = basename(canonicalize(directory.path));

    if (!pubspec.existsSync()) {
      throw Exception('File "$dirName/pubspec.yaml" does not exist.');
    }

    return fromString(content: await pubspec.readAsString());
  }

  // ...........................................................................
  /// Parses version from pubspec.yaml
  Version fromString({
    required String content,
  }) {
    late Pubspec pubspec;

    try {
      pubspec = Pubspec.parse(content);
    } on ParsedYamlException catch (e) {
      throw Exception(e.message);
    }

    if (pubspec.version == null) {
      throw Exception('Could not find version in "pubspec.yaml".');
    }

    return pubspec.version!;
  }
}

// .............................................................................
/// Mock class for FromPubspec
class MockFromPubspec extends mocktail.Mock implements FromPubspec {}
