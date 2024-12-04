import 'package:flutter/material.dart';
import 'scanner_page.dart';
import 'res/custom_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Industry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: CustomColors.panelBackground,
        brightness: Brightness.light,
        //primarySwatch: Color(0xFF2196F3),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(
              fontSize: 18.0,
            ),
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
          ),
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 18.0,
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: const TextStyle(fontSize: 18.0),
        ),
      ),
      home: const ScannerPage(),
    );
  }
}
