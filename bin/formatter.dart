// Copyright (c) 2015, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by a MIT-style license
// that can be found in the LICENSE file.

library molviewfmt;

import 'dart:io';
import 'dart:convert';

import 'package:glob/glob.dart';
import 'package:which/which.dart';

import 'gitignore.dart';

/// Object for formatter output
class FormatterResult {
  /// Has the formatter exited successfully?
  bool success;

  /// Store warning/info messages from the formatter.
  String stdout;

  /// Store error messages form the formatter.
  String stderr;

  /// Create FormatterResult.
  FormatterResult(this.success, this.stdout, this.stderr);
}

/// Get formatter arguments to format the specified file.
typedef List<String> FormatOneFileArgs(final String filepath);

/// Get formatter arguments to format all underlying files (these files are also
/// specified in the [files] property).
typedef List<String> FormatAllFilesArgs(final List<String> files);

/// Class to store license variables for convenience.
class LicenseVariables {
  /// Copyright holder that is mentioned in the rendered license notice.
  String copyrightHolder;

  /// SPDX license ID that is mentioned in the license notice.
  String licenseType;

  /// RegExp pattern for the license notice. Used to detect outdated licenses.
  String noticePattern;

  /// Rendered license notice. Used to match the license and to append the
  /// license. Only the license year is not rendered yet, it can be inserted
  /// by replacing '$year' with the desired year.
  String noticeRendered;

  /// Number of lines between first license notice line and first license notice
  /// pattern line.
  int patternOffset = 0;
}

/// molviewfmt formatter base class
///
/// Code should be formatted using a command-line application. By default
/// [CodeFormatter] executes a binary to format source files. You can override
/// this class to implement a special formatter that does not require an
/// installed binary.
class CodeFormatter {
  /// Name of the language this formatter can format.
  final String language;

  /// License variables.
  ///
  /// All license variables are stored in this object for convenience.
  LicenseVariables _license;

  /// Source file selector
  ///
  /// Glob describing the source files that should be formatted by this
  /// formatter.
  final Glob _glob;

  /// Formatter executable
  ///
  /// The name of the program that is used to format source files. Should be
  /// in the $PATH.
  final String _bin;

  /// Generates script for formatting one file.
  final FormatOneFileArgs _getArgsOne;

  /// Generates script for formatting all files.
  final FormatAllFilesArgs _getArgsAll;

  /// This message is displayed when the formatter is not installed.
  String _installMessage;

  /// Constructor
  CodeFormatter(this.language, final String glob, this._bin, this._getArgsOne,
      this._getArgsAll,
      {final String pub,
      final String npm,
      final String pip,
      final String website,
      final String noticeStart: '',
      final String noticeLineStart: '',
      final String noticeEnd: '',
      final String copyright: '',
      final String license: ''})
      : _glob = new Glob(glob) {
    // Generate license notice pattern.
    if (copyright.isNotEmpty && license.isNotEmpty) {
      _license = new LicenseVariables();
      _license.copyrightHolder = copyright;
      _license.licenseType = license;

      // Generate license notice pattern.
      _license.noticePattern = '''
Copyright \\(c\\) ([0-9]+), .*\\. All rights reserved\.
Use of this source code is governed by an? .*-style license
that can be found in the LICENSE file\\.''';

      // Decide indefinite article (i.e. 'a' or 'an').
      var article = license.startsWith(new RegExp('[AaEeIiOoUu]')) ? 'an' : 'a';

      // Generate license notice.
      _license.noticeRendered = '''
$noticeStart${noticeLineStart}Copyright (c) \$year, $copyright. All rights reserved.
${noticeLineStart}Use of this source code is governed by $article $license-style license
${noticeLineStart}that can be found in the LICENSE file.$noticeEnd''';

      // Find the offset between the rendered license notice and the license
      // notice pattern.
      _license.patternOffset = new RegExp(r'\n').allMatches(noticeStart).length;
    }

    // Generate installMessage.
    var installMessage =
        new StringBuffer("The program '${this._bin}' is not installed.");
    if (pub != null) {
      installMessage.write(' You can install it by typing:\n');
      installMessage.writeln('pub global activate $pub');
    } else if (npm != null) {
      installMessage.write(' You can install it by typing:\n');
      installMessage.writeln('npm install $npm -g');
    } else if (pip != null) {
      installMessage.write(' You can install it by typing:\n');
      installMessage.writeln('pip install --upgrade $pip');
    } else if (website != null) {
      installMessage.writeln(' See $website for installation instructions.');
    } else {
      installMessage.write('\n');
    }

    // Store installMessage.
    _installMessage = installMessage.toString();
  }

  /// Checks if the given filepath can be formated by this formatter.
  bool canFormat(String filepath) {
    return _glob.matches(filepath);
  }

  bool checkInstallation() {
    return whichSync(_bin, orElse: () => null) != null;
  }

  /// This method will check if the given file contains a license notice and
  /// will add one if none present.
  void addLicenseNotice(String filepath) {
    // Check if a license notice is defined.
    if (_license == null) {
      return;
    }

    // Open and read file.
    var file = new File(filepath);
    var lines = file.readAsLinesSync();
    var start = 0;

    // Test for shebang.
    if (lines.length > 0 && lines.first.startsWith('#!')) {
      // Make sure there is an empty line after the shebang.
      // Add empty line if the second line is empty or none exists.
      if ((lines.length > 1 && lines[1].isNotEmpty) || lines.length == 1) {
        // Insert empty line after the shebang.
        lines.insert(1, '');
      }
      // Move forward two lines.
      start += 2;
    }

    // Read license notice data into lists.
    var rlines = LineSplitter.split(_license.noticeRendered).toList();
    var plines = LineSplitter.split(_license.noticePattern).toList();
    assert(rlines.length == plines.length);

    // Determines if the lines should be written back into the file after the
    // loop has finished. This is used to write back changes that are made to
    // already existing license headers inside the loop.
    var writeAfterLoop = false;

    // If lines.length is less than start + hlines.length, it can never contain
    // a valid license.
    if (lines.length >= start + rlines.length) {
      // Match _licenseHeader.
      for (var i = 0; i < rlines.length; i++) {
        // The license notice is added by breaking out of this loop. This way
        // Files that contain no lines will also get a licence notice.
        // A license notice should be added when a mismatch it detected.
        if (rlines[i] != lines[start + i]) {
          // First check if this maybe is a licence notice line after all, but
          // it is outdated. If so, replace with an updated line from rlines.
          // You can only check if this is a licence notice when you're inside
          // the range of [_license.noticePattern].
          if (i >= _license.patternOffset) {
            var regex = new RegExp(plines[i - _license.patternOffset]);
            var match = regex.firstMatch(lines[start + i]);
            if (match != null) {
              var line = rlines[i];

              // If this is the first pattern line, it contains the year.
              // Replace '$year' from the rendered line with this year.
              if (i - _license.patternOffset == 0) {
                line = line.replaceFirst(r'$year', match.group(1));
              }
              lines[start + i] = line;

              // Write lines back into file when the loop is finished.
              writeAfterLoop = true;
            } else {
              // No match so break and add new license notice.
              break;
            }
          } else {
            // Not in the pattern range so break and add new license notice.
            break;
          }
        }
        if (i == rlines.length - 1) {
          // This was the last line, terminate the method.
          if (writeAfterLoop) {
            // Note that a terminating newline is added.
            file.writeAsStringSync(lines.join('\n') + '\n');
          }
          return;
        }
      }
    }

    // Insert new license notice.

    // Get rendered license notice with current year.
    var noticeRendered = _license.noticeRendered
        .replaceFirst(r'$year', new DateTime.now().year.toString());

    // Note that a blank line is inserted after the license notice.
    lines.insertAll(
        start, LineSplitter.split(noticeRendered).toList()..add(''));

    // Trim end of the file contents.
    // This is necessary if there were no contents after the license.
    while (lines.last.isEmpty) {
      lines.removeLast();
    }
    // Write new content back into file.
    // Note that a terminating newline is added.
    file.writeAsStringSync(lines.join('\n') + '\n');
  }

  /// This method is called when a file in the underlying directory is updated.
  /// It's up to the method to validate if it should format this file. If it
  /// does, it should return true.
  FormatterResult formatOne(String filepath, GitignoreMatcher gitignore) {
    if (!gitignore.exclude(filepath)) {
      if (checkInstallation()) {
        var output = Process.runSync(_bin, _getArgsOne(filepath));
        addLicenseNotice(filepath);
        return new FormatterResult(
            output.exitCode == 0, output.stdout, output.stderr);
      } else {
        return new FormatterResult(false, null, _installMessage);
      }
    } else {
      return new FormatterResult(false, null,
          'This file is excluded in your .gitignore file or by the provided command-line parameters.\n');
    }
  }

  /// Globs all files and runs the formatter.
  FormatterResult formatAll(GitignoreMatcher gitignore) {
    // Retrieve all underlying files that match the given glob.
    var fileEntities = _glob.listSync(followLinks: false);
    if (fileEntities.length > 0) {
      if (checkInstallation()) {
        // Generate and filter file list.
        var files = gitignore.filter(new List<String>.generate(
            fileEntities.length, (int i) => fileEntities[i].path));

        // Check if there are any files to be formatted.
        if (files.isNotEmpty) {
          var output = Process.runSync(_bin, _getArgsAll(files));
          files.forEach((String filepath) => addLicenseNotice(filepath));
          return new FormatterResult(
              output.exitCode == 0, output.stdout, output.stderr);
        } else {
          return new FormatterResult(true, null, null);
        }
      } else {
        return new FormatterResult(false, null, _installMessage);
      }
    } else {
      return new FormatterResult(true, null, null);
    }
  }
}
