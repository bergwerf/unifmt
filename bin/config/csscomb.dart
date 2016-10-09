// Copyright (c) 2015, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by a MIT-style license
// that can be found in the LICENSE file.

library unifmt.config.csscomb;

import 'dart:convert';

/// csscomb configuration generator
class CSSCombConfigGenerator {
  /// Store configuration map.
  Map<String, dynamic> _config;

  /// Constructor
  CSSCombConfigGenerator() : _config = new Map<String, dynamic>();

  /// Set option.
  void set(String key, dynamic value) {
    _config[key] = value;
  }

  /// Generate config string.
  String generate() {
    var encoder = new JsonEncoder();
    return encoder.convert(_config);
  }
}

/// Generate default csscomb config.
String getDefaultCSSCombConfig() {
  var config = new CSSCombConfigGenerator();
  config
    ..set('remove-empty-rulesets', true)
    ..set('always-semicolon', true)
    ..set('color-case', 'lower')
    ..set('block-indent', '  ')
    ..set('color-shorthand', true)
    ..set('element-case', 'lower')
    ..set('eof-newline', true)
    ..set('leading-zero', false)
    ..set('quotes', 'single')
    ..set('sort-order-fallback', 'abc')
    ..set('space-before-colon', '')
    ..set('space-after-colon', ' ')
    ..set('space-before-combinator', ' ')
    ..set('space-after-combinator', ' ')
    ..set('space-between-declarations', '\n')
    ..set('space-before-opening-brace', ' ')
    ..set('space-after-opening-brace', '\n')
    ..set('space-after-selector-delimiter', ' ')
    ..set('space-before-selector-delimiter', '')
    ..set('space-before-closing-brace', '\n')
    ..set('strip-spaces', true)
    ..set('tab-size', true)
    ..set('unitless-zero', true)
    ..set('vendor-prefix-align', true);
  return config.generate();
}
