// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// #############################################################################
import 'package:args/command_runner.dart';
import './commands/my_command.dart';

/// Gg Version
class GgVersion {
  /// Constructor
  GgVersion({
    required this.param,
    required this.log,
  });

  /// The param to work with
  final String param;

  /// The log function
  final void Function(String msg) log;

  /// The function to be executed
  Future<void> exec() async {
    log('Executing ggVersion with param $param');
  }
}

// #############################################################################
/// The command line interface for GgVersion
class GgVersionCmd extends Command<dynamic> {
  /// Constructor
  GgVersionCmd({required this.log}) {
    addSubcommand(MyCommand(log: log));
  }

  /// The log function
  final void Function(String message) log;

  // ...........................................................................
  @override
  final name = 'ggVersion';
  @override
  final description = 'Add your description here.';
}
