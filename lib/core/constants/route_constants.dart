class RouteConstants {
  RouteConstants._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String taskDetails = '/tasks/:id';
  static const String createTask = '/tasks/create';
  static const String editTask = '/tasks/:id/edit';

  static String taskDetailsPath(Object id) => '/tasks/$id';
  static String editTaskPath(Object id) => '/tasks/$id/edit';
}
