import 'package:flutter/foundation.dart';

/// Logs internal Mastro framework messages to the debug console.
///
/// Prefixes messages with `[MASTRO]:` to differentiate framework logs
/// from other output. Intended for internal use only.
void mastroLog(String message) {
  debugPrint('[MASTRO]: $message');
}

/// The default internal callback name used within the Mastro framework.
///
/// This is a reserved key for registering and retrieving default callbacks.
/// Intended for internal use only.
final defaultCallbacksName = '__mastro_internal__';
