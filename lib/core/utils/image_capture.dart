import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// What the photo becomes: a book cover (2:3) or a profile photo (1:1).
enum ImageCropShape {
  cover(
    ratioX: 2,
    ratioY: 3,
    maxWidth: 600,
    maxHeight: 900,
    title: 'Potong cover',
  ),
  square(
    ratioX: 1,
    ratioY: 1,
    maxWidth: 512,
    maxHeight: 512,
    title: 'Potong foto',
  );

  const ImageCropShape({
    required this.ratioX,
    required this.ratioY,
    required this.maxWidth,
    required this.maxHeight,
    required this.title,
  });

  final double ratioX;
  final double ratioY;
  final int maxWidth;
  final int maxHeight;
  final String title;
}

/// Thrown when the camera, the gallery or the cropper cannot be opened.
class ImageCaptureException implements Exception {
  const ImageCaptureException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Asks for Kamera or Galeri (unless [source] is given), lets the user crop
/// and rotate the photo to [shape], and returns it as a compressed JPEG
/// (quality 80, at most 600×900 for a cover, 512×512 for a profile photo),
/// well under the 1 MB the Storage rules allow. Null when cancelled.
Future<Uint8List?> pickAndCropImage(
  BuildContext context, {
  required ImageCropShape shape,
  ImageSource? source,
}) async {
  final chosen = source ?? await _askSource(context);
  if (chosen == null || !context.mounted) return null;

  final scheme = Theme.of(context).colorScheme;
  final dark = Theme.of(context).brightness == Brightness.dark;

  final XFile? picked;
  try {
    picked = await ImagePicker().pickImage(source: chosen);
  } catch (_) {
    throw const ImageCaptureException('Tidak bisa membuka galeri atau kamera.');
  }
  if (picked == null) return null;

  final CroppedFile? cropped;
  try {
    cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: CropAspectRatio(ratioX: shape.ratioX, ratioY: shape.ratioY),
      maxWidth: shape.maxWidth,
      maxHeight: shape.maxHeight,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 80,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: shape.title,
          toolbarColor: scheme.surface,
          toolbarWidgetColor: scheme.onSurface,
          statusBarLight: !dark,
          navBarLight: !dark,
          backgroundColor: dark ? Colors.black : scheme.surfaceContainerHighest,
          activeControlsWidgetColor: scheme.primary,
          cropFrameColor: scheme.primary,
          cropGridColor: scheme.outlineVariant,
          lockAspectRatio: true,
          hideBottomControls: false,
          cropStyle: shape == ImageCropShape.square
              ? CropStyle.circle
              : CropStyle.rectangle,
        ),
        IOSUiSettings(
          title: shape.title,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          doneButtonTitle: 'Selesai',
          cancelButtonTitle: 'Batal',
        ),
      ],
    );
  } catch (_) {
    throw const ImageCaptureException('Tidak bisa membuka pemotong foto.');
  }
  if (cropped == null) return null;
  return cropped.readAsBytes();
}

Future<ImageSource?> _askSource(BuildContext context) =>
    showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('image-source-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              key: const Key('image-source-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeri'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
