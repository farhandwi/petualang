import 'package:postgres/postgres.dart';

void main() async {
  print('Connecting to database...');
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'petualang',
    username: 'postgres',
    password: 'farhandwi',
  );

  await connection.open();
  print('Connected!');

  try {
    await connection.execute('''
      ALTER TABLE community_posts ADD COLUMN IF NOT EXISTS share_count INTEGER DEFAULT 0;
    ''');
    print('Migration complete!');
  } catch (e) {
    print('Error: \$e');
  } finally {
    await connection.close();
  }
}
