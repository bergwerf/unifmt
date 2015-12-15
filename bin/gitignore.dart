library molviewfmt.gitignore;

import 'dart:io';

import 'package:glob/glob.dart';

class GitignoreMatcher {
  /// Ignore these globs.
  List<Glob> _exclude = new List<Glob>();

  /// Force include these globs.
  List<Glob> _include = new List<Glob>();

  /// Add exclude rule. This method is used by the molviewfmt main program to
  /// hangle --ignore flags.
  void addExclude(String glob) {
    _exclude.add(new Glob(glob));
  }

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

  /// Internal method used for parsing the `.gitignore` file.
  void _parseGitignoreRule(String rule) {
    // Check if this is an include rule.
    bool forceInclude = rule.startsWith('!');
    if (forceInclude) {
      rule = rule.substring(1);
    }

    // Expand rule:
    // - Always start with `/**/` to select inside any folder.
    // - If the rule ends with `/`, add `**` to match all underlying files.
    // - If the rule ends with `/*`, add '*' to match all underlying files.
    // - Else add a rule that also checks if the file is in a directory with
    //   the specified name.
    var rules = new List<Glob>();

    // Add parent directory wildcard.
    if (rule.startsWith('/')) {
      rule = '/**' + rule;
    } else {
      rule = '/**/' + rule;
    }

    // Add child directory wildcard.
    if (rule.endsWith('/')) {
      // Only include directory selector.
      rules.add(new Glob(rule + '**'));
    } else if (rule.endsWith('/*')) {
      // Only include directory selector.
      rules.add(new Glob(rule + '*'));
    } else {
      // Also include file selector.
      rules..add(new Glob(rule))..add(new Glob(rule + '/**'));
    }

    // Insert rules
    if (forceInclude) {
      _include.addAll(rules);
    } else {
      _exclude.addAll(rules);
    }
  }

  /// The constructor will parse the given `.gitignore` file.
  GitignoreMatcher(String path) {
    // Open file.
    var file = new File(path);
    if (file.existsSync()) {
      // Read file.
      List<String> lines = file.readAsLinesSync();

      // Parse file.
      lines.forEach((String line) {
        if (!(line.startsWith('#') || line.trimLeft().isEmpty)) {
          _parseGitignoreRule(line);
        }
      });
    }
  }
}
