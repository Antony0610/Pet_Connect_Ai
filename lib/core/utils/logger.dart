import 'package:logger/logger.dart';

import 'package:petconnect_ai/core/config/app_config.dart';

/// Centralized logging for PetConnect AI.
///
/// Wraps the `logger` package with app-specific configuration. Verbosity is
/// controlled by the [AppConfig.isDebuggable] flag (debug builds log
/// everything; prod is quiet). Access via Riverpod (`loggerProvider`).
class AppLogger {
  AppLogger({required bool isDebuggable})
    : _logger = Logger(
        filter: isDebuggable
            ? DevelopmentFilter()
            : ProductionFilter(), // prod: error+ only
        printer: PrettyPrinter(
          methodCount: isDebuggable ? 2 : 0,
          errorMethodCount: 5,
          lineLength: 80,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
        output: ConsoleOutput(),
      );

  final Logger _logger;

  void trace(dynamic message) => _logger.t(message);
  void debug(dynamic message) => _logger.d(message);
  void info(dynamic message) => _logger.i(message);
  void warning(dynamic message) => _logger.w(message);
  void error(dynamic message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
  void fatal(dynamic message, [Object? error, StackTrace? stackTrace]) =>
      _logger.f(message, error: error, stackTrace: stackTrace);
}
