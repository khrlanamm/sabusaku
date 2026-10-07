import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/colors.dart';
import '../models/credential.dart';
import '../utils/csv_import.dart';
import '../utils/share_file.dart';
import 'dialogs.dart';

Future<void> shareCredentials(List<Credential> credentials) => shareCsv(
  fileName: 'kredensial-sabu-saku.csv',
  content: credentialsToCsv(credentials),
  subject: 'Kredensial awal Sabu Saku',
);

/// Shows a new or reset password. It cannot be retrieved again afterwards, so
/// the dialog only closes on an explicit confirmation.
Future<void> showCredentialDialog(
  BuildContext context,
  Credential credential, {
  String title = 'Password sementara',
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(credential.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _Field(label: 'Username', value: credential.username),
            const SizedBox(height: 8),
            _Field(
              key: const Key('credential-password'),
              label: 'Password',
              value: credential.password,
            ),
            const SizedBox(height: 12),
            Text(
              'Password ini hanya tampil sekali dan wajib diganti saat masuk.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => shareCredentials([credential]),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Bagikan'),
          ),
          FilledButton(
            key: const Key('credential-close'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Sudah dicatat'),
          ),
        ],
      );
    },
  );
}

class _Field extends StatelessWidget {
  const _Field({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkMuted,
                  ),
                ),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Salin $label',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) showSnack(context, '$label disalin');
            },
          ),
        ],
      ),
    );
  }
}
