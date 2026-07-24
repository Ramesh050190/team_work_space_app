class CacheException implements Exception {
  const CacheException({this.message = 'Cache error'});

  final String message;

  @override
  String toString() => 'CacheException(message: $message)';
}
