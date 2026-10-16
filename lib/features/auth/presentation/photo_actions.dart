import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/dialogs.dart';
import '../data/auth_repository.dart';
import '../domain/session.dart';

enum _PhotoAction { gallery, camera, google, remove }

/// "Ganti foto": gallery, camera, the Google account photo, or none.
Future<void> showPhotoActions(
  BuildContext context,
  WidgetRef ref,
  Session session,
) async {
  final hasPhoto = session.profile.photoUrl != null;
  final googlePhoto = session.googlePhotoUrl;
  final action = await showModalBottomSheet<_PhotoAction>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const Key('photo-gallery'),
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari galeri'),
            onTap: () => Navigator.of(context).pop(_PhotoAction.gallery),
          ),
          ListTile(
            key: const Key('photo-camera'),
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Ambil foto'),
            onTap: () => Navigator.of(context).pop(_PhotoAction.camera),
          ),
          if (session.hasGoogle &&
              googlePhoto != null &&
              googlePhoto != session.profile.photoUrl)
            ListTile(
              key: const Key('photo-google'),
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('Pakai foto Google'),
              onTap: () => Navigator.of(context).pop(_PhotoAction.google),
            ),
          if (hasPhoto)
            ListTile(
              key: const Key('photo-remove'),
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Hapus foto',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => Navigator.of(context).pop(_PhotoAction.remove),
            ),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;

  final auth = ref.read(authRepositoryProvider);
  switch (action) {
    case _PhotoAction.gallery || _PhotoAction.camera:
      final XFile? file;
      try {
        file = await ImagePicker().pickImage(
          source: action == _PhotoAction.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );
      } catch (_) {
        if (context.mounted) {
          showSnack(context, 'Tidak bisa membuka galeri atau kamera.');
        }
        return;
      }
      if (file == null || !context.mounted) return;
      final bytes = await file.readAsBytes();
      if (bytes.length >= 1024 * 1024) {
        if (context.mounted) {
          showSnack(context, 'Foto terlalu besar. Pilih foto lain.');
        }
        return;
      }
      if (!context.mounted) return;
      final type = file.mimeType ?? _mimeOf(file.name);
      await runWithProgress(
        context,
        () => auth.uploadPhoto(session, bytes, contentType: type),
      );
    case _PhotoAction.google:
      await runWithProgress(context, () => auth.useGooglePhoto(session));
    case _PhotoAction.remove:
      await runWithProgress(context, () => auth.removePhoto(session));
  }
}

String _mimeOf(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}
