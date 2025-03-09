import 'package:flutter/material.dart';

Map<String, Map<String, String>> localizedStrings = {
  'appTitle': {
    'en': 'rawdispenser - Organize and copy RAW files',
    'ko': 'rawdispenser - RAW 파일 정리 및 복사기',
  },
  'sourceDrag': {
    'en': 'Drag RAW Source Directory Here',
    'ko': '복사할 RAW 파일이 있는 디렉토리를 이곳에 드래그하세요',
  },
  'destinationDrag': {
    'en': 'Drag RAW Destination Directory Here',
    'ko': 'RAW 파일을 복사, 정리할 디렉토리를 이곳에 드래그하세요',
  },
  'sourcePath': {
    'en': 'Source Directory Path',
    'ko': '출발 디렉토리 경로',
  },
  'totalFiles': {
    'en': 'Total Files',
    'ko': '파일 개수',
  },
  'destinationPath': {
    'en': 'Destination Directory Path',
    'ko': '도착 디렉토리 경로',
  },
  'copyButton': {
    'en': 'Copy',
    'ko': '복사',
  },
  'copyToClipboardButton': {
    'en': 'Copy to clipboard',
    'ko': '클립보드로 복사',
  },
  'resultDialogTitle': {
    'en': 'Result',
    'ko': '결과',
  },
  'renamedFilesDialogContent': {
    'en': 'The following files were copied with new names:\n{renamedList}',
    'ko': '다음 파일들이 새로운 이름으로 복사되었습니다:\n{renamedList}',
  },
  'copyCompleteMessage': {
    'en': 'Copy completed successfully.',
    'ko': '복사가 성공적으로 완료되었습니다.',
  },
  'failToGetExif': {
    'en': 'Failed to get EXIF information.',
    'ko': 'EXIF 정보를 얻지 못했습니다',
  }
};

String getLocalizedString(BuildContext context, String key) {
  final locale = Localizations.localeOf(context).languageCode;
  return localizedStrings[key]?[locale] ?? localizedStrings[key]?['en'] ?? '';
}
