/// Build flavors: `dev`, `stage`, `prod`.
enum AppEnvironment { development, staging, production }

/// Per-flavor app configuration (name, API, mock toggle).
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.useTaskMock,
  });

  final AppEnvironment environment;
  final String flavor;
  final String appName;
  final String apiBaseUrl;
  final bool useTaskMock;

  bool get isDevelopment => environment == AppEnvironment.development;

  static AppConfig fromFlavor(String flavor) {
    switch (flavor.toLowerCase().trim()) {
      case 'prod':
      case 'production':
        return production;
      case 'stage':
      case 'staging':
      case 'stg':
        return staging;
      case 'dev':
      case 'development':
      default:
        return development;
    }
  }

  static const AppConfig development = AppConfig(
    environment: AppEnvironment.development,
    flavor: 'dev',
    appName: 'Team Workspace Dev',
    apiBaseUrl: 'https://api-dev.teamworkspace.com',
    useTaskMock: true,
  );

  static const AppConfig staging = AppConfig(
    environment: AppEnvironment.staging,
    flavor: 'stage',
    appName: 'Team Workspace Stage',
    apiBaseUrl: 'https://api-stage.teamworkspace.com',
    useTaskMock: true,
  );

  static const AppConfig production = AppConfig(
    environment: AppEnvironment.production,
    flavor: 'prod',
    appName: 'Team Workspace',
    apiBaseUrl: 'https://api.teamworkspace.com',
    useTaskMock: bool.fromEnvironment('USE_TASK_MOCK', defaultValue: true),
  );
}
