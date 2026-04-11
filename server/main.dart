import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/env_config.dart';

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  // Load environment variables
  EnvConfig.init();
  
  // Initialize database connection on startup
  print('🚀 Starting Petualang Server...');
  await Database.connection;
  print('🌐 Server running at http://${ip.address}:$port');
  return serve(handler, ip, port);
}
