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
  
  // Server settings
  static int get port => int.tryParse(_dotEnv['PORT'] ?? '8080') ?? 8080;
}
