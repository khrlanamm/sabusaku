import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../data/auth_repository.dart';
import 'auth_widgets.dart';

/// Email sign-up for students who do not use Google. The account only gets
/// into a school once the email is verified and the school listed it.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .register(email: _email.text, password: _password.text);
      TextInput.finishAutofillContext();
      // The router moves on to "Verifikasi email".
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = mapError(error).userMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar akun')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const InfoBanner(
                        child: Text(
                          'Pakai email yang didaftarkan sekolahmu. Setelah '
                          'mendaftar, buka email verifikasi yang kami kirim.'
                          '\n\nPunya akun Google dengan email itu? Kembali '
                          'dan pilih "Masuk dengan Google".',
                        ),
                      ),
                      const SizedBox(height: 20),
                      EmailField(
                        key: const Key('register-email'),
                        controller: _email,
                      ),
                      const SizedBox(height: 14),
                      NewPasswordFields(
                        password: _password,
                        confirm: _confirm,
                        label: 'Password',
                        onSubmitted: _submit,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        ErrorBanner(message: _error!),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        key: const Key('register-submit'),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const ButtonProgress()
                            : const Text('Daftar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
