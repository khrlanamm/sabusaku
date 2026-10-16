import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/palette.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/policy/terms.dart';
import '../../../core/widgets/brand.dart';
import '../data/auth_repository.dart';
import 'auth_widgets.dart';

/// The short version of hosting/ketentuan.html.
const _rules = <(IconData, String)>[
  (
    Icons.badge_outlined,
    'Pakai akunmu sendiri, isi data yang benar, dan jaga password-mu.',
  ),
  (
    Icons.edit_note,
    'Jurnal, komentar, nama, dan foto profil harus sopan. Tanpa konten '
        'seksual, kekerasan, atau kebencian SARA.',
  ),
  (
    Icons.front_hand_outlined,
    'Jangan melecehkan, merundung, atau mempermalukan orang lain.',
  ),
  (
    Icons.lock_outline,
    'Jangan membuka data pribadi orang lain, seperti nomor HP, alamat, '
        'atau foto.',
  ),
  (
    Icons.copyright,
    'Tulis dengan kata-katamu sendiri. Jangan menyalin isi buku terlalu '
        'banyak.',
  ),
  (
    Icons.flag_outlined,
    'Lihat yang melanggar? Pakai menu Laporkan. Konten yang melanggar bisa '
        'dihapus dan penggunanya dikeluarkan.',
  ),
];

/// "Ketentuan Penggunaan": every user accepts the terms before anything
/// else, even "Lengkapi akun". The router keeps them here until the server
/// recorded the current version.
class TermsScreen extends ConsumerStatefulWidget {
  const TermsScreen({super.key});

  @override
  ConsumerState<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends ConsumerState<TermsScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _accept() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).acceptTerms();
      // The watched profile now carries the new version; the router leaves
      // this screen on its own.
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = context.palette;

    return Scaffold(
      key: const Key('terms-screen'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandLogo(size: 72)),
                  const SizedBox(height: 12),
                  Text(
                    'Ketentuan Penggunaan',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: palette.heading,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sabu Saku dipakai bersama teman dan guru di sekolahmu. '
                    'Sebelum mulai, setujui aturan ini dulu, ya.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Column(
                        children: [
                          for (final (icon, text) in _rules)
                            _Rule(icon: icon, text: text),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton.icon(
                      key: const Key('terms-read-full'),
                      onPressed: () => launchUrl(
                        Uri.parse(termsUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Baca selengkapnya'),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    ErrorBanner(message: _error!),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('terms-accept'),
                    onPressed: _busy ? null : _accept,
                    child: _busy
                        ? const ButtonProgress()
                        : const Text('Saya setuju'),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    key: const Key('terms-sign-out'),
                    onPressed: _busy
                        ? null
                        : () => ref.read(authRepositoryProvider).signOut(),
                    child: const Text('Keluar'),
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

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: palette.infoTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: palette.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
