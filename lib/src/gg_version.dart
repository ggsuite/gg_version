// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// #############################################################################
import 'package:args/command_runner.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_version/gg_version.dart';

/// The command line interface for GgVersion
class GgVersion extends Command<dynamic> {
  /// Constructor
  GgVersion({required this.ggLog}) {
    addSubcommand(AddVersionTag(ggLog: ggLog));
    addSubcommand(IsVersioned(ggLog: ggLog));
    addSubcommand(FromGit(ggLog: ggLog));
    addSubcommand(FromPubspec(ggLog: ggLog));
    addSubcommand(FromChangelog(ggLog: ggLog));
    addSubcommand(AllVersions(ggLog: ggLog));
    addSubcommand(ConsistentVersion(ggLog: ggLog));
    addSubcommand(IncreaseBuild(ggLog: ggLog));
  }

  /// The log function
  final GgLog ggLog;

  // ...........................................................................
  @override
  final name = 'ggVersion';
  @override
  final description = 'A collection of packages for managing package versions';
}
