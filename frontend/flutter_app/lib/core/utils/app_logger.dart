/// AppLogger — lightweight structured logging for the Flutter app.
///
/// Uses dart:developer (zero external package) which outputs to:
///   - `flutter run` terminal output
///   - Android Logcat (filter by tag "CropDiag")
///   - Xcode Console / iOS device logs
///
/// Usage:
///   AppLogger.info('Market data loaded', tag: 'Market');
///   AppLogger.error('API failed', error: e, stackTrace: st);
///   AppLogger.debug('User tapped diagnose');
library;

import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// Log levels
enum LogLevel { debug, info, warning, error }

class AppLogger {
  static const String _defaultTag = 'CropDiag';

  // ── Public API ─────────────────────────────────────────────────────────────

  static void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  static void warning(String message, {String? tag, Object? error}) {
    _log(LogLevel.warning, message, tag: tag, error: error);
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // In release mode, only log warnings and errors
    if (!kDebugMode && level == LogLevel.debug) return;

    final prefix = _levelPrefix(level);
    final logTag = tag ?? _defaultTag;
    final fullMessage = '[$logTag] $prefix $message';

    dev.log(
      fullMessage,
      name: logTag,
      level: _levelValue(level),
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  static String _levelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:   return '🔍 DEBUG';
      case LogLevel.info:    return 'ℹ️  INFO ';
      case LogLevel.warning: return '⚠️  WARN ';
      case LogLevel.error:   return '🔴 ERROR';
    }
  }

  static int _levelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:   return 500;
      case LogLevel.info:    return 800;
      case LogLevel.warning: return 900;
      case LogLevel.error:   return 1000;
    }
  }
}
