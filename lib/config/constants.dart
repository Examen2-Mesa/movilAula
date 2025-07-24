class AppConstants {
  // API
  static const String apiBaseUrl = 'http://143.244.165.131:8001';

  // Strings
  static const String appName = 'AsistIA';
  static const String versionNumber = '1.0.0';

  // Formatos de fecha
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Configuración de predicción
  static const double prediccionUmbralBajo = 60.0;
  static const double prediccionUmbralMedio = 80.0;

  // Intervalos de tiempo
  static const int tokenExpirationHours = 24;
  static const int cacheExpirationMinutes = 30;

  // Máximos
  static const int maxObservacionLength = 200;
  static const int maxParticipacionesPorClase = 5;

  // Preferencias
  static const String prefThemeMode = 'theme_mode';
  static const String prefLastPeriodoId = 'last_periodo_id';
  static const String prefLastCursoId = 'last_curso_id';

  // NUEVAS CONSTANTES PARA EL DISEÑO
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;

  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // Clave pública para validar tokens
  static const String jwtPublicKey = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnzyis1Zjz4BbJWCSbJPo
... (aquí va la clave completa) ...
57yCNH4GjW/+OvXYMV1Wz5wiIDgZ36W9tBFmFMm3RnCNUYJTeRkw4JY1OvkcgOZD
QIDAQAB
-----END PUBLIC KEY-----
''';
}
