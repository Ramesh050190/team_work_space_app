class ApiConstants {
  ApiConstants._();

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const String tasksPath = '/tasks';
  static String taskDetailsPath(int id) => '/tasks/$id';
  static String updateTaskStatusPath(int id) => '/tasks/$id/status';

  /// do change here in future for pagination count
  static const int defaultPageSize = 10;
}
