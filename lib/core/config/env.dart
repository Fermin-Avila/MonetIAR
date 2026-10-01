// lib/core/config/env.dart
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_KEY');
  static const useMock = bool.fromEnvironment('USE_MOCK');
}