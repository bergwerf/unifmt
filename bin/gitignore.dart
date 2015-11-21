library molviewfmt.gitignore;

import 'dart:io';

import 'package:glob/glob.dart';

class GitignoreMatcher {
  /// Ignore these globs.
  List<Glob> _exclude = new List<Glob>();

  /// Force include these globs.
  List<Glob> _include = new List<Glob>();

  /// Check if the given filepath should be excluded based on the gitignore
  /// rules.
  bool exclude(String filepath) {
    // Try to find include rule.
    for (var i = 0; i < _include.length; i++) {
      if (_include[i].matches(filepath)) {
        return false;
      }
    }

    // No include rule? Try to find exclude rule.
    for (var i = 0; i < _exclude.length; i++) {
      if (_exclude[i].matches(filepath)) {
        return true;
      }
    }

    // No exclude, no force include => include file
    return false;
  }

  /// Removes excluded paths from the given input.
  List<String> filter(List<String> input) {
    return new List.from(input.where((String filepath) => !exclude(filepath)));
  }

  /// The constructor will parse the given `.gitignore` file for rules that
  /// apply to the given glob.
  GitignoreMatcher(String path, String selector) {
    // Create selector glob.
    var glob = new Glob(selector);

    // Open file.
    var file = new File(path);
    if (file.existsSync()) {
      // Read file.
      List<String> lines = file.readAsLinesSync();

      // Parse file.
      lines.forEach((String line) {
        if (!(line.startsWith('#') || line.trimLeft().isEmpty) &&
            glob.matches(line)) {
          if (line.startsWith('!')) {
            _include.add(new Glob(line.substring(1)));
          } else {
            _exclude.add(new Glob(line));
          }
        }
      });
    }
  }
}
