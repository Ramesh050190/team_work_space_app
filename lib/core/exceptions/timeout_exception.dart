class TimeoutException implements Exception {
  const TimeoutException([this.message = 'Request timed out']);

  final String message;
}
