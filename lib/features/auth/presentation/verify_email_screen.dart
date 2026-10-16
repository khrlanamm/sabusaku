import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/dialogs.dart';
import '../data/auth_repository.dart';
import '../domain/session.dart';
import 'auth_widgets.dart';

/// Waits for the user to open the verification link from their inbox.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _busy = false;

  Future<void> _check() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final verified = await ref.read(authRepositoryProvider).reloadUser();
      // Verified: the session stream claims the account and the router
      // leaves this screen.
      if (!verified && mounted) {
        showSnack(
          context,
          'Email belum terverifikasi. Buka tautan di email lalu coba lagi.',
        );
      }
    } catch (error) {
      if (mounted) showErrorSnack(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final sent = await runWithProgress(context, () async {
      await ref.read(authRepositoryProvider).resendVerification();
      return true;
    });
    if (sent == true && mounted) {
      showSnack(context, 'Email verifikasi dikirim ulang.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(authStateProvider).value;
    final email = state is AuthNeedsVerification ? state.email : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi email'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('Keluar'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cek email kamu',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Kami mengirim tautan verifikasi ke ',
                        ),
                        TextSpan(
                          text: email,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(
                          text:
                              '. Buka tautan itu, lalu kembali ke sini dan '
                              'tekan tombol di bawah. Tidak ada di kotak '
                              'masuk? Periksa folder Spam.',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('verify-check'),
                    onPressed: _busy ? null : _check,
                    child: _busy
                        ? const ButtonProgress()
                        : const Text('Saya sudah verifikasi'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('verify-resend'),
                    onPressed: _busy ? null : _resend,
                    child: const Text('Kirim ulang email'),
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
