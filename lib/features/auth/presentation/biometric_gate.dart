// lib/features/auth/presentation/biometric_gate.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:monetiar/features/auth/application/auth_providers.dart';

/// Pide Face ID / passcode al abrir y al volver de segundo plano (>30 s).
/// En web no aplica. Mientras está bloqueada, el contenido no se construye.
class BiometricGate extends ConsumerStatefulWidget {
  const BiometricGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<BiometricGate> with WidgetsBindingObserver {
  static const _relockAfter = Duration(seconds: 30);

  final _auth = LocalAuthentication();
  bool _unlocked = kIsWeb;
  bool _busy = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!_unlocked) _authenticate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final at = _backgroundedAt;
      _backgroundedAt = null;
      if (at != null && _unlocked && DateTime.now().difference(at) > _relockAfter) {
        setState(() => _unlocked = false);
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_busy) return;
    _busy = true;
    try {
      // Dispositivo sin ningún bloqueo configurado: no hay nada que pedir.
      if (!await _auth.isDeviceSupported()) {
        if (mounted) setState(() => _unlocked = true);
        return;
      }
      final ok = await _auth.authenticate(
        localizedReason: 'Desbloqueá MonetiAr para ver tus finanzas',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (mounted) setState(() => _unlocked = ok);
    } catch (_) {
      if (mounted) setState(() => _unlocked = false);
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_rounded, size: 56, color: cs.primary),
          const SizedBox(height: 16),
          const Text('MonetiAr bloqueada',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _authenticate,
            icon: const Icon(Icons.face_rounded),
            label: const Text('Desbloquear'),
          ),
          TextButton(
            onPressed: () => ref.read(supabaseClientProvider).auth.signOut(),
            child: const Text('Cerrar sesión'),
          ),
        ]),
      ),
    );
  }
}