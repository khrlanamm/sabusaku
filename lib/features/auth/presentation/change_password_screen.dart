import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/dialogs.dart';
import '../data/auth_repository.dart';
import 'auth_widgets.dart';

/// "Ubah password", or "Atur password" for an account that only signs in
/// with Google.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  late final _email = TextEditingController(
    text: ref.read(currentSessionProvider).profile.email,
  );
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = ref.read(authRepositoryProvider);
    final hasPassword = ref.read(currentSessionProvider).hasPassword;
    try {
      if (hasPassword) {
        await auth.changePassword(
          currentPassword: _current.text,
          newPassword: _next.text,
        );
      } else {
        await auth.setPassword(_next.text);
      }
      TextInput.finishAutofillContext();
      if (!mounted) return;
      showSnack(
        context,
        hasPassword ? 'Password berhasil diganti.' : 'Password tersimpan.',
      );
      Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      final mapped = mapError(error);
      showSnack(
        context,
        mapped.code == AppErrorCode.sessionExpired
            ? 'Demi keamanan, keluar lalu masuk lagi sebelum mengatur password.'
            : mapped.userMessage,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPassword = ref.watch(
      currentSessionProvider.select((session) => session.hasPassword),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(hasPassword ? 'Ubah password' : 'Atur password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!hasPassword) ...[
                    const InfoBanner(
                      child: Text(
                        'Akunmu masuk dengan Google. Buat password agar bisa '
                        'masuk juga dengan email dan password.',
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Read-only, but its hint lets Android save the new pair.
                  EmailField(controller: _email, readOnly: true),
                  const SizedBox(height: 14),
                  if (hasPassword) ...[
                    TextFormField(
                      key: const Key('password-current'),
                      controller: _current,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password saat ini',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: ObscureToggle(
                          obscure: _obscure,
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.password],
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                  NewPasswordFields(
                    password: _next,
                    confirm: _confirm,
                    onSubmitted: _submit,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('password-submit'),
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const ButtonProgress()
                        : const Text('Simpan password'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
