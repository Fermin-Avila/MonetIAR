// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:monetiar/app.dart';
import 'package:monetiar/core/config/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_AR');
  if (!Env.useMock) {
    if (Env.supabaseUrl.isEmpty || Env.supabaseKey.isEmpty) {
      throw StateError(
        'Faltan SUPABASE_URL / SUPABASE_KEY. Ejecutá con --dart-define-from-file=env.json');
    }
    await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabaseKey);
  }
  runApp(const ProviderScope(child: MonetiArApp()));
}