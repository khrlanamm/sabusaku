import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/dialogs.dart';
import '../data/auth_repository.dart';
import '../domain/credentials.dart';

/// Password change. With [forced] the user arrived with an initial or reset
/// password and cannot use the app until it is replaced (PRD BR-16).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key, required this.forced});

  final bool forced;

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = ref.read(authRepositoryProvider);
    try {
      await auth.changePassword(
        session: ref.read(currentSessionProvider),
        currentPassword: widget.forced ? null : _current.text,
        newPassword: _next.text,
      );
      // Forced flow: the router leaves this screen once the flag clears.
      if (!mounted || widget.forced) return;
      showSnack(context, 'Password berhasil diganti.');
      Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      final mapped = mapError(error);
      showSnack(context, mapped.userMessage);
      // An initial password older than the recent-login window needs a fresh
      // sign-in before it can be changed.
      if (mapped.code == AppErrorCode.sessionExpired) await auth.signOut();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    InputDecoration decoration(String label) => InputDecoration(
      labelText: label,
      suffixIcon: IconButton(
        tooltip: _obscure ? 'Tampilkan password' : 'Sembunyikan password',
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.forced ? 'Buat password baru' : 'Ubah password'),
        automaticallyImplyLeading: !widget.forced,
        actions: [
          if (widget.forced)
            TextButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: const Text('Keluar'),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.forced) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.sky,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Kamu masuk dengan password sementara. Buat password '
                      'baru yang hanya kamu ketahui untuk melanjutkan.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  TextFormField(
                    key: const Key('password-current'),
                    controller: _current,
                    obscureText: _obscure,
                    decoration: decoration('Password saat ini'),
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  key: const Key('password-new'),
                  controller: _next,
                  obscureText: _obscure,
                  decoration: decoration(
                    'Password baru',
                  ).copyWith(helperText: 'Minimal $minPasswordLength karakter'),
                  textInputAction: TextInputAction.next,
                  validator: validateNewPassword,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('password-confirm'),
                  controller: _confirm,
                  obscureText: _obscure,
                  decoration: decoration('Ulangi password baru'),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) =>
                      value != _next.text ? 'Password tidak sama' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('password-submit'),
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Simpan password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
