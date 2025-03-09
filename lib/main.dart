import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/drag_drop_page.dart';

void main() {
  runApp(RawdispenserApp());
}

class RawdispenserApp extends StatelessWidget {
  const RawdispenserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', ''),
        Locale('ko', ''),
      ],
      home: DragDropPage(),
    );
  }
}
