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
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Increase the build number in the pubspec.yaml file.
class IncreaseBuild extends DirCommand<void> {
  /// Constructor.
  IncreaseBuild({
    required super.ggLog,
    super.name = 'increase-build',
    super.description = 'Increase the build number in the pubspec.yaml file.',
  });

  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    final file = File(join(directory.path, 'pubspec.yaml'));

    if (!await file.exists()) {
      throw Exception('pubspec.yaml file not found in ${directory.path}');
    }

    await inFile(file: file);
  }

  // ...........................................................................
  /// Increase the build number in the pubspec.yaml file.
  Future<void> inFile({required File file}) async {
    // Read the contents of the pubspec.yaml file
    final originalYamlFile = await file.readAsString();

    // Increase the build number
    final modifiedYamlFile = inString(originalYamlFile);

    // Write the new contents back to the pubspec.yaml
    await file.writeAsString(modifiedYamlFile);
  }

  // ...........................................................................
  /// Increase the build number in the pubspec.yaml file.
  String inString(String contents) {
    final yamlMap = loadYaml(contents);
    final yamlVersion = yamlMap?['version'] as String?;
    if (yamlVersion == null) {
      throw Exception('Version key not found in pubspec.yaml');
    }
    final version = Version.parse(yamlVersion);
    final buildComponents = version.build as List<dynamic>;
    final buildNumber =
        (buildComponents.isEmpty ? 0 : buildComponents.first) + 1;

    // Increment the build number
    final newVersion = Version(
      version.major,
      version.minor,
      version.patch,
      build: buildNumber.toString(),
    );

    // Replace the version in the yaml string
    final yamlEditor = YamlEditor('')..update([], yamlMap);
    yamlEditor.update(['version'], newVersion.toString());

    // Write the new contents back to the pubspec.yaml
    return yamlEditor.toString();
  }
}
