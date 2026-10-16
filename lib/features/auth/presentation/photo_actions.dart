import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/image_capture.dart';
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
      final Uint8List? picked;
      try {
        // Cropped to a square and compressed to a small JPEG on the device.
        picked = await pickAndCropImage(
          context,
          shape: ImageCropShape.square,
          source: action == _PhotoAction.camera
              ? ImageSource.camera
              : ImageSource.gallery,
        );
      } on ImageCaptureException catch (error) {
        if (context.mounted) showSnack(context, error.message);
        return;
      }
      final bytes = picked;
      if (bytes == null || !context.mounted) return;
      if (bytes.length >= 1024 * 1024) {
        showSnack(context, 'Foto terlalu besar. Pilih foto lain.');
        return;
      }
      await runWithProgress(context, () => auth.uploadPhoto(session, bytes));
    case _PhotoAction.google:
      await runWithProgress(context, () => auth.useGooglePhoto(session));
    case _PhotoAction.remove:
      await runWithProgress(context, () => auth.removePhoto(session));
  }
}
