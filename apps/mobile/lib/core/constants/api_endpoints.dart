class ApiEndpoints {
  // Ganti host dengan 10.0.2.2 untuk Android Emulator atau IP lokal untuk device fisik
  static const String baseUrl = 'http://10.0.2.2:8080/v1';
  static const String wsBaseUrl = 'ws://10.0.2.2:8080/ws';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String account = '/auth/account';

  // User
  static const String me = '/users/me';
  static const String mySessions = '/users/me/sessions';
  static const String myStats = '/users/me/stats';
  static const String exportData = '/users/me/export';

  // Personas
  static const String personas = '/personas';

  // Motions & Templates
  static const String motions = '/motions';
  static const String sessionTemplates = '/session-templates';

  // Sessions
  static const String sessions = '/sessions';
  static const String joinSession = '/sessions/join';
  static String sessionDetail(String id) => '/sessions/$id';
  static String sessionStart(String id) => '/sessions/$id/start';
  static String sessionPause(String id) => '/sessions/$id/pause';
  static String sessionResume(String id) => '/sessions/$id/resume';
  static String sessionEnd(String id) => '/sessions/$id/end';
  static String sessionResults(String id) => '/sessions/$id/results';
  static String sessionTranscript(String id) => '/sessions/$id/transcript';
  static String submitArgument(String id) => '/sessions/$id/arguments';

  // WebSocket arena
  static String debateWebSocket(String sessionId, String token) =>
      '$wsBaseUrl/debate/$sessionId?token=$token';
}
