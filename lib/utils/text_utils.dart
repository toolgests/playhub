import 'dart:async';

import 'package:flutter/foundation.dart';

final RegExp _lineBreakTag = RegExp(r'<br\s*/?>', caseSensitive: false);
final RegExp _blockEndTag = RegExp(r'</(p|div|li)>', caseSensitive: false);
final RegExp _anyTag = RegExp(r'<[^>]*>');
final RegExp _spaces = RegExp(r'[ \t]+');
final RegExp _blankLines = RegExp(r'\n{3,}');

/// Converts light HTML from catalog descriptions into readable plain text.
String plainText(String input) {
  if (input.isEmpty) return input;
  final text = input
      .replaceAll(_lineBreakTag, '\n')
      .replaceAll(_blockEndTag, '\n')
      .replaceAll(_anyTag, '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll(_spaces, ' ')
      .replaceAll(_blankLines, '\n\n');
  return text.trim();
}

/// Runs the latest callback once input has been quiet for [delay].
class Debouncer {
  Debouncer(this.delay);

  final Duration delay;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() => cancel();
}
