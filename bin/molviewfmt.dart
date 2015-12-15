/// molviewfmt command-line tool

import 'dart:io';
import 'dart:async';

import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:watcher/watcher.dart';

import 'formatter.dart';
import 'formatters.dart';
import 'gitignore.dart';

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

  // Create glob for matching the top-level gitignore file.
  final gitignoreGlob = new Glob('.gitignore');

  // Parse .gitignore for file matching.
  var gitignore = new GitignoreMatcher('.gitignore');

  // Create formatters.
  var formatters = await getFormatters();

  // Bootstrap formatters.
  if (options['watch']) {
    // Setup watching.
    var watcher = new DirectoryWatcher(Directory.current.path);

    // Declare subscription.
    StreamSubscription subscription;

    // Handle watch events.
    onWatchEvent(WatchEvent event) async {
      // Only handle file updates.
      if (event.type == ChangeType.MODIFY) {
        print(event);
        // Check if this is the top-level gitignore file.
        if (gitignoreGlob.matches(event.path)) {
          // Reload .gitignore file.
          gitignore = new GitignoreMatcher('.gitignore');
        } else {
          // Search for suitable formatter.
          for (CodeFormatter formatter in formatters) {
            if (formatter.canFormat(event.path)) {
              // Cancel subscription.
              await subscription.cancel();

              // Format file.
              var result = formatter.formatOne(event.path, gitignore);

              // Reattatch subscription.
              subscription = watcher.events.listen(onWatchEvent);

              // Print results.
              if (result.success) {
                if (options['verbose'] && result.stdout != null) {
                  stdout.write(result.stdout);
                }
              } else {
                stderr.write(result.stderr != null
                    ? result.stderr
                    : 'The ${formatter.language} formatter exited with a non-zero status.\n');
                // Do not exit when watching files.
                //exit(1);
              }
            }
          }
        }
      }
    }

    // Attatch watcher.
    subscription = watcher.events.listen(onWatchEvent);
  } else {
    // Glob all files and reformat.
    for (CodeFormatter formatter in formatters) {
      if (options['verbose']) {
        print('Running ${formatter.language} formatter');
      }
      var result = formatter.formatAll(gitignore);

      // Print results.
      if (result.success) {
        if (options['verbose'] && result.stdout != null) {
          stdout.write(result.stdout);
        }
      } else {
        if (result.stdout != null) {
          stderr.write(result.stdout);
        }
        if (result.stderr != null) {
          stderr.write(result.stderr);
        }
        if (result.stdout == null && result.stderr == null) {
          stderr.writeln(
              'The ${formatter.language} formatter exited with a non-zero status.');
        }
        exit(1);
      }
    }
  }
}
