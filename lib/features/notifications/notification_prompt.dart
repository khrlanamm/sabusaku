import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/data/auth_repository.dart';
import 'notification_service.dart';

/// Explains why notifications are useful before Android shows its own
/// permission dialog (docs/05 §6). Shown once per account on a device; the
/// student can still turn notifications on later from the profile.
class NotificationPermissionPrompt extends ConsumerStatefulWidget {
  const NotificationPermissionPrompt({super.key});

  @override
  ConsumerState<NotificationPermissionPrompt> createState() =>
      _NotificationPermissionPromptState();
}

class _NotificationPermissionPromptState
    extends ConsumerState<NotificationPermissionPrompt> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAsk());
  }

  Future<void> _maybeAsk() async {
    final service = ref.read(notificationServiceProvider);
    final session = ref.read(currentSessionProvider);
    if (!await service.shouldExplainPermission(session) || !mounted) return;

    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined),
        title: const Text('Aktifkan notifikasi?'),
        content: const Text(
          'Kami memberi tahu saat guru mengomentari jurnalmu. Tidak ada '
          'notifikasi lain.',
        ),
        actions: [
          TextButton(
            key: const Key('notification-later'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Nanti saja'),
          ),
          FilledButton(
            key: const Key('notification-allow'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Izinkan'),
          ),
        ],
      ),
    );
    await service.markPermissionExplained(session);
    if (allow == true) await service.requestPermission();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Profile row that shows whether comment notifications are on and lets the
/// student turn them on.
class NotificationSettingTile extends ConsumerStatefulWidget {
  const NotificationSettingTile({super.key});

  @override
  ConsumerState<NotificationSettingTile> createState() =>
      _NotificationSettingTileState();
}

class _NotificationSettingTileState
    extends ConsumerState<NotificationSettingTile> {
  bool? _granted;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final granted = await ref
        .read(notificationServiceProvider)
        .isPermissionGranted();
    if (mounted) setState(() => _granted = granted);
  }

  Future<void> _enable() async {
    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermission();
    if (!mounted) return;
    setState(() => _granted = granted);
    if (!granted) {
      // Android stops showing the dialog after repeated denials.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin notifikasi ditolak. Aktifkan lewat Pengaturan HP › '
            'Aplikasi › Sabu Saku › Notifikasi.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final granted = _granted;
    // A row of the "Pengaturan" card (AccountSettings).
    return ListTile(
      leading: Icon(
        granted == true
            ? Icons.notifications_active_outlined
            : Icons.notifications_off_outlined,
      ),
      title: const Text('Notifikasi komentar guru'),
      subtitle: Text(switch (granted) {
        true => 'Aktif',
        false => 'Belum aktif',
        null => 'Memeriksa…',
      }),
      trailing: granted == false
          ? TextButton(onPressed: _enable, child: const Text('Aktifkan'))
          : null,
    );
  }
}
