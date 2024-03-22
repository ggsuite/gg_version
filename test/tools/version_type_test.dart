// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_version/src/tools/version_type.dart';
import 'package:test/test.dart';

void main() {
  group('VersionType', () {
    test('versionTypeToString', () {
      expect(versionTypeToString(VersionType.pubspec), 'pubspec');
      expect(versionTypeToString(VersionType.changeLog), 'changeLog');
      expect(versionTypeToString(VersionType.gitHead), 'gitHead');
    });

    test('parse from string', () {
      expect(VersionType.values.byName('pubspec'), VersionType.pubspec);
    });
  });
}
