import 'dart:io' as io;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

Future<int> countFiles(String sourcePath) async {
  int count = 0;
  final dir = io.Directory(sourcePath);
  await for (var entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is io.File) {
      count++;
    }
  }
  return count;
}

String generateTimeHash(DateTime time) {
  final formattedTime =
      "${time.year.toString().padLeft(4, '0')}${time.month.toString().padLeft(2, '0')}${time.day.toString().padLeft(2, '0')}${time.hour.toString().padLeft(2, '0')}${time.minute.toString().padLeft(2, '0')}${time.second.toString().padLeft(2, '0')}";
  return md5.convert(utf8.encode(formattedTime)).toString().substring(0, 8);
}

Future<DateTime?> getExifOriginalDate(String filePath) async {
  try {
    final String exifToolFileName;
    if (io.Platform.isWindows) {
      exifToolFileName = './win/exiftool.exe';
    } else if (io.Platform.isMacOS) {
      exifToolFileName = './mac/exiftool.out';
    } else {
      return null;
    }

    // exiftool -DateTimeOriginal
    final result =
        await io.Process.run(exifToolFileName, ['-DateTimeOriginal', filePath]);
    if (result.exitCode != 0) return null;
    final output = result.stdout as String;
    // "Date/Time Original              : 2025:02:15 12:12:14"
    final regex = RegExp(
        r'Date/Time Original\s*:\s*(\d{4}):(\d{2}):(\d{2})\s+(\d{2}):(\d{2}):(\d{2})');
    final match = regex.firstMatch(output);
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      final second = int.parse(match.group(6)!);
      return DateTime(year, month, day, hour, minute, second);
    }
  } catch (e) {
    return null;
  }
  return null;
}

(int year, int month, int day) extractDateComponents(DateTime date) {
  return (date.year, date.month, date.day);
}

Future<void> showCopyCompletionDialog({
  required BuildContext context,
  required String Function(BuildContext, String) getLocalizedString,
  required List<String> renamedFiles,
}) async {
  final String dialogContent;
  if (renamedFiles.isNotEmpty) {
    dialogContent = getLocalizedString(context, 'renamedFilesDialogContent')
        .replaceAll('{renamedList}', renamedFiles.join('\n'));
  } else {
    dialogContent = getLocalizedString(context, 'copyCompleteMessage');
  }

  final List<Widget> actions = [];
  if (renamedFiles.isNotEmpty) {
    actions.add(
      TextButton(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: renamedFiles.join('\n')));
        },
        child: Text(getLocalizedString(context, 'copyToClipboardButton')),
      ),
    );
  }
  actions.add(
    TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('OK'),
    ),
  );

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(getLocalizedString(context, 'resultDialogTitle')),
      content: SingleChildScrollView(
        child: Text(dialogContent),
      ),
      actions: actions,
    ),
  );
}

Future<void> copyFiles({
  required String sourcePath,
  required String destinationPath,
  required BuildContext context,
  required String Function(BuildContext, String) getLocalizedString,
  required void Function(int processed, int total) progressCallback,
}) async {
  if (sourcePath.isEmpty || destinationPath.isEmpty) return;

  final sourceDir = io.Directory(sourcePath);
  if (!await sourceDir.exists()) return;

  final totalFiles = await countFiles(sourcePath);
  int processed = 0;

  final hash = generateTimeHash(DateTime.now());

  List<String> renamedFiles = [];

  await for (var entity
      in sourceDir.list(recursive: true, followLinks: false)) {
    if (entity is io.File) {
      processed++;

      DateTime? exifDate = await getExifOriginalDate(entity.path);
      if (exifDate == null) {
        if (!context.mounted) return;

        final List<Widget> actions = [];
        actions.add(
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        );

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(getLocalizedString(context, 'resultDialogTitle')),
            content: SingleChildScrollView(
              child: Text(getLocalizedString(context, 'failToGetExif')),
            ),
            actions: actions,
          ),
        );

        return;
      }

      final (year, month, day) = extractDateComponents(exifDate);

      // destination/year/year-month/year-month-day
      final monthStr = month.toString().padLeft(2, '0');
      final dayStr = day.toString().padLeft(2, '0');
      final destDirPath = p.join(destinationPath, '$year', '$year-$monthStr',
          '$year-$monthStr-$dayStr');
      final destDir = io.Directory(destDirPath);
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      final fileName = p.basename(entity.path);
      final destFilePath = p.join(destDirPath, fileName);
      final destFile = io.File(destFilePath);

      String finalDestFilePath = destFilePath;

      if (await destFile.exists()) {
        final newFileName = "dup${hash}_$fileName";
        finalDestFilePath = p.join(destDirPath, newFileName);
        renamedFiles.add(finalDestFilePath);
      }

      await entity.copy(finalDestFilePath);
      progressCallback(processed, totalFiles);
    }
  }

  if (!context.mounted) return;

  await showCopyCompletionDialog(
    context: context,
    getLocalizedString: getLocalizedString,
    renamedFiles: renamedFiles,
  );
}
