// lib/features/auth/presentation/auth_gate.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetiar/features/auth/application/auth_providers.dart';
import 'package:monetiar/features/auth/presentation/biometric_gate.dart';
import 'package:monetiar/features/auth/presentation/login_screen.dart';
import 'package:monetiar/features/dashboard/presentation/dashboard_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(authSessionProvider).when(
          loading: () => const Scaffold(
            body: Center(child: CupertinoActivityIndicator(radius: 14)),
          ),
          error: (_, _) => const LoginScreen(),
          data: (session) => session == null
              ? const LoginScreen()
              : const BiometricGate(child: DashboardScreen()),
        );
  }
}