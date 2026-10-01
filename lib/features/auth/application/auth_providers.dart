// lib/features/auth/application/auth_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session, Supabase, SupabaseClient;

final supabaseClientProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authSessionProvider = StreamProvider<Session?>((ref) async* {
  final auth = ref.watch(supabaseClientProvider).auth;
  yield auth.currentSession;
  yield* auth.onAuthStateChange.map((state) => state.session);
});