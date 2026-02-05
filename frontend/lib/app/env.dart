class AppEnv {
  AppEnv._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String wsEventsPath = String.fromEnvironment(
    'WS_EVENTS_PATH',
    defaultValue: '/ws/events',
  );

  static String get wsEventsUrl {
    final String explicit = const String.fromEnvironment(
      'WS_EVENTS_URL',
      defaultValue: '',
    );
    if (explicit.trim().isNotEmpty) {
      return explicit;
    }

    final Uri apiUri = Uri.parse(apiBaseUrl);
    final String wsScheme = apiUri.scheme == 'https' ? 'wss' : 'ws';
    return apiUri.replace(scheme: wsScheme, path: wsEventsPath).toString();
  }
}
