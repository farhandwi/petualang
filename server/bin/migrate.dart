import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/env_config.dart';

void main() async {
  EnvConfig.init();
  final conn = await Database.connection;
  await conn.execute('''
    ALTER TABLE articles 
    ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0;
  ''');
  print('Migration success');
  await Database.close();
}
