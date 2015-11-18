/// molviewfmt command-line tool

import 'dart:io';

import 'package:args/args.dart';

import 'formatter.dart';
import 'formatters.dart';

main(List<String> args) async {
  // Create CLI args parser.
  var parser = new ArgParser();
  parser
    ..addFlag('verbose',
        abbr: 'v',
        defaultsTo: false,
        help: 'Output non-critical formatting messages.')
    ..addFlag('watch',
        abbr: 'w',
        defaultsTo: false,
        help: 'Watch current directory for changes and reformat them.');

  // Parse CLI args.
  final options = parser.parse(args);

  // Create formatters.
  var formatters = await getFormatters();

  // Bootstrap formatters.
  if (options['watch']) {
    // Start DirectoryWatcher.
    Directory.current
        .watch(events: FileSystemEvent.MODIFY, recursive: true)
        .listen((FileSystemEvent event) {
      // Search for suitable formatter.
      for (CodeFormatter formatter in formatters) {
        if (formatter.canFormat(event.path)) {
          // Format file.
          var result = formatter.formatOne(event.path);

          // Print results.
          if (result.success) {
            if (options['verbose'] && result.stdout != null) {
              print(result.stdout);
            }
          } else {
            print(result.stderr != null
                ? result.stderr
                : 'The ${formatter.language} formatter exited with a non-zero status.');
          }
        }
      }
    });
  } else {
    // Glob all files and reformat.
    for (CodeFormatter formatter in formatters) {
      if (options['verbose']) {
        print('Running ${formatter.language} formatter\n');
      }
      var result = formatter.formatAll();

      // Print results.
      if (result.success) {
        if (options['verbose'] && result.stdout != null) {
          print(result.stdout);
        }
      } else {
        print(result.stderr != null
            ? result.stderr
            : 'The ${formatter.language} formatter exited with a non-zero status.');
      }
    }
  }
}
