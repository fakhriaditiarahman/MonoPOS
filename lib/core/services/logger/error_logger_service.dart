import '../../utilities/console_logger.dart';

/// Global error logging service
class ErrorLoggerService {
  ErrorLoggerService();

  /// Log error to console
  void log({
    required Object error,
    StackTrace? stackTrace,
    String? title,
    String? message,
    String? state,
  }) {
    ce(error, title: title, message: message, state: state);
  }
}
