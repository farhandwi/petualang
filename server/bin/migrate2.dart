import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/env_config.dart';

void main() async {
  EnvConfig.init();
  final conn = await Database.connection;
  
  await conn.execute('''
    ALTER TABLE articles 
    ADD COLUMN IF NOT EXISTS likes_count INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS comments_count INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS share_count INTEGER DEFAULT 0;
  ''');

  await conn.execute('''
    CREATE TABLE IF NOT EXISTS article_comments (
      id SERIAL PRIMARY KEY,
      article_id INTEGER REFERENCES articles(id) ON DELETE CASCADE,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      content TEXT NOT NULL,
      created_at TIMESTAMPTZ DEFAULT NOW()
    );
  ''');

  print('Migration success');
  await Database.close();
}
