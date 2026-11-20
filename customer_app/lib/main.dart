import 'package:flutter/material.dart';
import 'api.dart';
import 'screens.dart';

const brand = Color(0xFF147D5A);
const ink = Color(0xFF172B25);
const canvas = Color(0xFFF6F8F5);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.loadToken();
  runApp(const QuickDeliverApp());
}

class QuickDeliverApp extends StatelessWidget {
  const QuickDeliverApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'QuickDeliver',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(seedColor: brand, brightness: Brightness.light),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas, foregroundColor: ink, centerTitle: false,
        elevation: 0, titleTextStyle: TextStyle(color: ink, fontSize: 21, fontWeight: FontWeight.w800),
      ),
      cardTheme: CardThemeData(
        color: Colors.white, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFFE8EEE9))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFE3EAE5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFE3EAE5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: brand, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: brand, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), textStyle: const TextStyle(fontWeight: FontWeight.w700),
      )),
    ),
    home: Api.token == null ? const LoginScreen() : const HomeScreen(),
  );
}