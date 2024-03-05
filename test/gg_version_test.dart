// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_capture_print/gg_capture_print.dart';
import 'package:gg_version/gg_version.dart';
import 'package:path/path.dart';
import 'package:recase/recase.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];

  setUp(() {
    messages.clear();
  });

  group('GgVersion()', () {
    // #########################################################################
    group('GgVersion', () {
      final ggGit = GgVersion(log: (msg) => messages.add(msg));

      final CommandRunner<void> runner = CommandRunner<void>(
        'ggVersion',
        'Description goes here.',
      )..addCommand(ggGit);

      // .......................................................................
      test('should show all sub commands', () async {
        // Iterate all files in lib/src/commands
        // and check if they are added to the command runner
        // and if they are added to the help message
        final subCommands = Directory('lib/src/commands')
            .listSync(recursive: false)
            .where(
              (file) => file.path.endsWith('.dart'),
            )
            .map(
              (e) => basename(e.path)
                  .replaceAll('.dart', '')
                  .replaceAll('_', '-')
                  .replaceAll('gg-', ''),
            )
            .toList();

        await capturePrint(
          log: messages.add,
          code: () async => await runner.run(['ggVersion', '--help']),
        );

        for (final subCommand in subCommands) {
          final ggSubCommand = subCommand.pascalCase;

          expect(
            hasLog(messages, subCommand),
            isTrue,
            reason: '\nMissing subcommand "$ggSubCommand"\n'
                'Please open  "lib/src/gg_git.dart" and add\n'
                '"addSubcommand($ggSubCommand(log: log));',
          );
        }
      });
    });
  });
}
