import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/routes.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/theme_controls.dart';
import '../../../core/widgets/dialogs.dart';
import '../data/auth_repository.dart';
import '../domain/session.dart';
import 'auth_widgets.dart';

/// Explains the app and how a school can join (hosting/daftar-sekolah.html).
final schoolSignupUrl = Uri.parse('https://sabusaku.web.app/daftar-sekolah');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  bool _showingNotRegistered = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.listenManual(authStateProvider, (_, next) {
      if (!mounted) return;
      if (next.hasError) {
        setState(() {
          _busy = false;
          _error = mapError(next.error!).userMessage;
        });
        return;
      }
      final state = next.value;
      if (state is AuthNotRegistered) {
        setState(() => _busy = false);
        _showNotRegistered(state.email);
      } else if (state is AuthSignedOut) {
        setState(() => _busy = false);
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
          .signInWithEmail(email: _email.text, password: _password.text);
      // Offers to save the email and password (Android Autofill).
      TextInput.finishAutofillContext();
      // The router redirects once the session resolves.
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = mapError(error).userMessage;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final signedIn = await ref
          .read(authRepositoryProvider)
          .signInWithGoogle();
      if (!signedIn && mounted) setState(() => _busy = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = mapError(error).userMessage;
      });
    }
  }

  Future<void> _showNotRegistered(String email) async {
    if (_showingNotRegistered) return;
    _showingNotRegistered = true;
    // After the frame that put this screen in place.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NotRegisteredDialog(email: email),
    );
    _showingNotRegistered = false;
    await ref.read(authRepositoryProvider).signOut();
  }

  Future<void> _showForgotPassword() async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => _ForgotPasswordDialog(initialEmail: _email.text),
    );
    if (sent == true && mounted) {
      showSnack(
        context,
        'Jika email terdaftar, tautan untuk membuat password baru sudah '
        'dikirim. Periksa juga folder Spam.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        actions: const [ThemeToggleButton(), SizedBox(width: 4)],
      ),
      body: SafeArea(
        top: false,
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
                      const Center(child: BrandLogo(size: 104)),
                      Text(
                        'Sabu Saku',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Satu Bulan Satu Buku',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      EmailField(
                        key: const Key('login-email'),
                        controller: _email,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('login-password'),
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: ObscureToggle(
                            obscure: _obscure,
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Wajib diisi'
                            : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          key: const Key('login-forgot'),
                          onPressed: _busy ? null : _showForgotPassword,
                          child: const Text('Lupa password?'),
                        ),
                      ),
                      if (_error != null) ...[
                        ErrorBanner(message: _error!),
                        const SizedBox(height: 14),
                      ],
                      FilledButton(
                        key: const Key('login-submit'),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const ButtonProgress()
                            : const Text('Masuk'),
                      ),
                      const SizedBox(height: 16),
                      const OrDivider(),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        key: const Key('login-google'),
                        onPressed: _busy ? null : _signInWithGoogle,
                        icon: const GoogleMark(),
                        label: const Text('Masuk dengan Google'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Belum punya akun?',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          TextButton(
                            key: const Key('login-register'),
                            onPressed: _busy
                                ? null
                                : () => context.push(Routes.register),
                            child: const Text('Daftar'),
                          ),
                        ],
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

/// "Harap Menghubungi Administrator Sekolah": the email belongs to no school.
class NotRegisteredDialog extends StatelessWidget {
  const NotRegisteredDialog({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      key: const Key('dialog-not-registered'),
      icon: Icon(Icons.school_outlined, color: theme.colorScheme.primary),
      title: const Text('Harap Menghubungi Administrator Sekolah'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Email '),
                TextSpan(
                  text: email,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const TextSpan(
                  text:
                      ' belum terdaftar di sekolah mana pun. Minta '
                      'penanggung jawab Sabu Saku di sekolahmu untuk '
                      'menambahkan email ini.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ingin mendaftarkan sekolah Anda?',
            style: theme.textTheme.bodyMedium,
          ),
          TextButton(
            key: const Key('link-school-signup'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => launchUrl(
              schoolSignupUrl,
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('Pelajari di sini'),
          ),
        ],
      ),
      actions: [
        FilledButton(
          key: const Key('dialog-not-registered-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

class _ForgotPasswordDialog extends ConsumerStatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  ConsumerState<_ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail.trim());
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (mounted) Navigator.of(context).pop(true);
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
    return AlertDialog(
      title: const Text('Lupa password?'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Masukkan email akunmu. Kami kirim tautan untuk membuat '
              'password baru.\n\nAkun Google tanpa password? Pakai "Masuk '
              'dengan Google" saja.',
            ),
            const SizedBox(height: 14),
            EmailField(controller: _email, autofocus: true),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('forgot-send'),
          onPressed: _busy ? null : _send,
          child: _busy ? const ButtonProgress() : const Text('Kirim'),
        ),
      ],
    );
  }
}
