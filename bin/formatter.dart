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
  FormatterResult(this.success, this.stdout, this.stderr) {}
}

/// Get formatter arguments to format the specified file.
typedef List<String> FormatOneFileArgs(final String filepath);

/// Get formatter arguments to format all underlying files (these files are also
/// specified in the [files] property).
typedef List<String> FormatAllFilesArgs(final List<String> files);

/// molviewfmt formatter base class
///
/// Code should be formatted using a command-line application. By default
/// [CodeFormatter] executes a binary to format source files. You can override
/// this class to implement a special formatter that does not require an
/// installed binary.
class CodeFormatter {
  /// Name of the language this formatter can format.
  final String _language;

  /// Get _language.
  String get language => _language;

  /// License header
  ///
  /// If this String is empty the program will not check for license headers.
  String _licenseHeader = '';

  /// Glob describing the source files that should be formatted by this
  /// formatter.
  final Glob _glob;

  /// Formatter binary name. This is used to valiadate the installation of the
  /// formatter.
  final String _bin;

  /// Generates script for formatting one file.
  final FormatOneFileArgs _getArgsOne;

  /// Generates script for formatting all files.
  final FormatAllFilesArgs _getArgsAll;

  /// This message is displayed when the formatter is not installed.
  String _installMessage;

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
    if (_licenseHeader.isEmpty) {
      return;
    }

    var file = new File(filepath);
    var lines = file.readAsLinesSync();
    var start = 0;

    // Test for shebang.
    if (lines.length > 0 && lines.first.startsWith('#!')) {
      // Make sure there is an empty line after the shebang.
      if (lines.length > 1 && !lines[1].isEmpty) {
        // Insert empty line after the shebang.
        lines.insert(1, '');
      }
      // Move forward two lines.
      start += 2;
    }

    var hlines = LineSplitter.split(_licenseHeader).toList();
    // If lines.length is less than start + hlines.length, it can never contain
    // a valid license.
    if (lines.length >= start + hlines.length) {
      // Match _licenseHeader.
      for (var i = 0; i < hlines.length; i++) {
        // The license notice is added by breaking out of this loop. This way
        // Files that contain no lines will also get a licence notice.
        // A license notice should be added when a mismatch it detected.
        if (hlines[i] != lines[start + i]) {
          break;
        } else if (i == hlines.length - 1) {
          // This was the last line, terminate the method.
          return;
        }
      }
    }

    // Insert license notice.
    lines.insertAll(start, hlines);
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
        if (!files.isEmpty) {
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

  CodeFormatter(this._language, final String glob, this._bin, this._getArgsOne,
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
    // Generate license notice.
    if (copyright.isNotEmpty && license.isNotEmpty) {
      var year = new DateTime.now().year;
      _licenseHeader =
          '''$noticeStart${noticeLineStart}Copyright (c) $year, $copyright. All rights reserved.
${noticeLineStart}Use of this source code is governed by an $license-style license
${noticeLineStart}that can be found in the LICENSE file.$noticeEnd\n\n''';
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
}
