import 'package:dotenv/dotenv.dart';

class EnvConfig {
  static final _dotEnv = DotEnv(includePlatformEnvironment: true);

  static void init() {
    _dotEnv.load();
    print('📦 Loaded environment variables from .env file.');
  }

  // Database settings
  static String get dbHost => _dotEnv['DB_HOST'] ?? 'localhost';
  static int get dbPort => int.tryParse(_dotEnv['DB_PORT'] ?? '5432') ?? 5432;
  static String get dbName => _dotEnv['DB_NAME'] ?? 'petualang';
  static String get dbUser => _dotEnv['DB_USER'] ?? 'postgres';
  static String get dbPassword => _dotEnv['DB_PASSWORD'] ?? 'farhandwi';

  // Xendit settings
  static String get xenditSecretKey => _dotEnv['XENDIT_SECRET_KEY'] ?? '';

  // Google OAuth Client IDs (untuk validasi `aud` pada id_token).
  // Daftarkan ketiganya di Google Cloud Console — server menerima id_token
  // dari Web/Android/iOS sehingga `aud` bisa salah satu dari ini.
  static String get googleClientIdWeb => _dotEnv['GOOGLE_CLIENT_ID_WEB'] ?? '';
  static String get googleClientIdAndroid => _dotEnv['GOOGLE_CLIENT_ID_ANDROID'] ?? '';
  static String get googleClientIdIos => _dotEnv['GOOGLE_CLIENT_ID_IOS'] ?? '';

  static List<String> get googleClientIds => [
        googleClientIdWeb,
        googleClientIdAndroid,
        googleClientIdIos,
      ].where((id) => id.isNotEmpty).toList();

  // Server settings
  static int get port => int.tryParse(_dotEnv['PORT'] ?? '8080') ?? 8080;
}
