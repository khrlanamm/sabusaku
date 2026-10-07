import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes [content] to a temporary CSV file and opens the Android share sheet.
Future<void> shareCsv({
  required String fileName,
  required String content,
  String? subject,
}) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  // BOM so Excel reads UTF-8 names correctly.
  await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(content)]);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv', name: fileName)],
      subject: subject,
    ),
  );
}
