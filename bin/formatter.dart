library molviewfmt;

import 'dart:io';

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
/// [CodeFormatter] executes a shell script to format source files. You can
/// override this class to implement special behaviour.
class CodeFormatter {
  /// Name of the language this formatter can format.
  final String _language;

  /// Get _language.
  String get language => _language;

  /// Gitignore rules for this language.
  GitignoreMatcher _gitignore;

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

  /// This method is called when a file in the underlying directory is updated.
  /// It's up to the method to validate if it should format this file. If it
  /// does, it should return true.
  FormatterResult formatOne(String filepath) {
    if (checkInstallation()) {
      if (!_gitignore.exclude(filepath)) {
        var output = Process.runSync(_bin, _getArgsOne(filepath));
        return new FormatterResult(
            output.exitCode == 0, output.stdout, output.stderr);
      } else {
        return new FormatterResult(
            false, null, 'This file is excluded in your .gitignore file.');
      }
    } else {
      return new FormatterResult(false, null, _installMessage);
    }
  }

  /// Globs all files and runs the formatter.
  FormatterResult formatAll() {
    var fileEntities = _glob.listSync(followLinks: false);
    if (fileEntities.length > 0) {
      if (checkInstallation()) {
        var files = new List<String>.generate(
            fileEntities.length, (int i) => fileEntities[i].path);
        var output =
            Process.runSync(_bin, _getArgsAll(_gitignore.filter(files)));
        return new FormatterResult(
            output.exitCode == 0, output.stdout, output.stderr);
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
      final String website})
      : _glob = new Glob(glob) {
    // Create gitignore matcher.
    _gitignore = new GitignoreMatcher('.gitignore', glob);

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
