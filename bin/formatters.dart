import 'dart:io';
import 'dart:async';

import 'formatter.dart';
import 'config/tidy.dart';
import 'config/csscomb.dart';

/// Return set with all used [CodeFormatter] instances.
Future<Set<CodeFormatter>> getFormatters() async {
  // Get system temporary files directory.
  var systemTmpDir = Directory.systemTemp;

  // Create formatters.
  var formatters = new Set<CodeFormatter>();

  // Dart formatter
  formatters.add(new CodeFormatter(
      'Dart',
      '**/*.dart',
      'dartfmt',
      (final String file) => ['-w', file],
      (final List<String> files) => files..insert(0, '-w'),
      pub: 'dart_style'));

  // Go formatter
  formatters.add(new CodeFormatter(
      'Go',
      '**/*.go',
      'gofmt',
      (final String file) => ['-w', file],
      (final List<String> files) => files..insert(0, '-w')));

  // Python formatter
  formatters.add(new CodeFormatter(
      'Python',
      '**/*.py',
      'autopep8',
      (final String file) => ['-a', '-a', '-i', file],
      (final List<String> files) =>
          files..insertAll(0, ['-a', '-a', '-r', '-i']),
      pip: 'autopep8'));

  // JavaScript formatter
  formatters.add(new CodeFormatter(
      'JavaScript',
      '**/*.js',
      'standard',
      (final String file) => ['--format', file],
      (final List<String> files) => files..insert(0, '--format'),
      npm: 'standard'));

  // Write tidy configuration to temporary file.
  var tidyConfigFile =
      await new File('${systemTmpDir.path}/molviewfmt/tidy.yaml')
          .create(recursive: true);
  await tidyConfigFile.writeAsString(getDefaultTidyConfig());
  // HTML formtter
  formatters.add(new CodeFormatter(
      'HTML',
      '**/*.html',
      'tidy',
      (final String file) => ['-config', tidyConfigFile.path, file],
      (final List<String> files) =>
          files..insertAll(0, ['-config', tidyConfigFile.path]),
      website: 'http://www.html-tidy.org/'));

  // Write csscomb configuration to temporary file.
  var csscombConfigFile =
      await new File('${systemTmpDir.path}/molviewfmt/csscomb.json')
          .create(recursive: true);
  await csscombConfigFile.writeAsString(getDefaultCSSCombConfig());
  // CSS formatter
  formatters.add(new CodeFormatter(
      'CSS',
      '**/*.css',
      'csscomb',
      (final String file) => ['--config', csscombConfigFile.path, file],
      (final List<String> files) =>
          files..insertAll(0, ['--config', csscombConfigFile.path]),
      npm: 'csscomb'));
  // Sass formatter
  formatters.add(new CodeFormatter(
      'Sass',
      '**/*.scss',
      'csscomb',
      (final String file) => ['--config', csscombConfigFile.path, file],
      (final List<String> files) =>
          files..insertAll(0, ['--config', csscombConfigFile.path]),
      npm: 'csscomb'));

  // Bash formatter
  formatters.add(new CodeFormatter('Bash', '**/*.sh', 'bashbeautify',
      (final String file) => [file], (final List<String> files) => files,
      pip: 'bashbeautify'));

  // Return formatters.
  return formatters;
}
