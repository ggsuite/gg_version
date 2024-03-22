// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// The type of versions we can have
enum VersionType {
  /// Version set in pubspec.yaml
  pubspec,

  /// Version set in README.md
  changeLog,

  /// Version set in git tag
  gitHead,
}

/// Converts a versionType to string
String versionTypeToString(VersionType type) => type.name;
