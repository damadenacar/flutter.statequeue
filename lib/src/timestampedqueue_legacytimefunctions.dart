typedef TimeFunction = int Function();

/// These are the legacy functions to get the time
class LegacyTimeFunction {
  /// Returns the current time in milliseconds
  static int millisecondsNow() => DateTime.now().millisecondsSinceEpoch;
  /// Returns the current time in microseconds
  static int microsecondsNow() => DateTime.now().microsecondsSinceEpoch;
}
