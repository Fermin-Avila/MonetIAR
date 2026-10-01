// lib/features/auth/presentation/login_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetiar/features/auth/application/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@') || password.length < 8) {
      setState(() => _message = 'Ingresá un email válido y una contraseña de al menos 8 caracteres.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final auth = ref.read(supabaseClientProvider).auth;
      if (_signUp) {
        final res = await auth.signUp(email: email, password: password);
        if (res.session == null && mounted) {
          setState(() => _message = 'Cuenta creada. Confirmá tu email para poder ingresar.');
        }
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (_) {
      if (mounted) setState(() => _message = 'No se pudo conectar. Revisá tu conexión.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, size: 56, color: cs.primary),
                    const SizedBox(height: 16),
                    Text('MonetiAr',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(_signUp ? 'Creá tu cuenta' : 'Ingresá a tu cuenta',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 28),
                    CupertinoTextField(
                      controller: _email,
                      placeholder: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      padding: const EdgeInsets.all(14),
                    ),
                    const SizedBox(height: 12),
                    CupertinoTextField(
                      controller: _password,
                      placeholder: 'Contraseña',
                      obscureText: true,
                      autofillHints: [
                        _signUp ? AutofillHints.newPassword : AutofillHints.password,
                      ],
                      onSubmitted: (_) => _submit(),
                      padding: const EdgeInsets.all(14),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(_message!,
                          textAlign: TextAlign.center, style: TextStyle(color: cs.error)),
                    ],
                    const SizedBox(height: 20),
                    CupertinoButton.filled(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : Text(_signUp ? 'Crear cuenta' : 'Ingresar'),
                    ),
                    CupertinoButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _signUp = !_signUp;
                                _message = null;
                              }),
                      child: Text(_signUp ? 'Ya tengo cuenta' : 'Crear cuenta nueva'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}