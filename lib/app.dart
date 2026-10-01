// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:monetiar/core/theme/app_theme.dart';
import 'package:monetiar/core/config/env.dart';
import 'package:monetiar/features/auth/presentation/auth_gate.dart';
import 'package:monetiar/features/home/presentation/home_shell.dart';

class MonetiArApp extends StatelessWidget {
  const MonetiArApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MonetiAr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Env.useMock ? const HomeShell() : const AuthGate(),
    );
  }
}