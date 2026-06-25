import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static Future<void> load() async {
    await dotenv.load(fileName: '.env.example');
  }

  static String get supabaseUrl {
    const value = String.fromEnvironment('SUPABASE_URL');
    return value.isNotEmpty ? value : dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get supabaseAnonKey {
    const value = String.fromEnvironment('SUPABASE_ANON_KEY');
    return value.isNotEmpty ? value : dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
