// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// #############################################################################
import 'package:args/command_runner.dart';
import 'package:gg_version/gg_version.dart';

/// The command line interface for GgVersion
class GgVersion extends Command<dynamic> {
  /// Constructor
  GgVersion({required this.log}) {
    addSubcommand(AddVersionTag(log: log));
    addSubcommand(IsVersioned(log: log));
    addSubcommand(FromGit(log: log));
    addSubcommand(FromPubspec(log: log));
    addSubcommand(FromChangelog(log: log));
    addSubcommand(AllVersions(log: log));
    addSubcommand(ConsistentVersion(log: log));
  }

  /// The log function
  final void Function(String message) log;

  // ...........................................................................
  @override
  final name = 'ggVersion';
  @override
  final description = 'A collection of packages for managing package versions';
}
