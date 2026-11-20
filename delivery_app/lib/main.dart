import 'package:flutter/material.dart';
import 'api.dart';
import 'screens.dart';

const partnerBrand = Color(0xFF2456C5);
const partnerInk = Color(0xFF17233B);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.loadToken();
  runApp(const DeliveryApp());
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'QuickDeliver Partner',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      colorScheme: ColorScheme.fromSeed(seedColor: partnerBrand, brightness: Brightness.light),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF5F7FB), foregroundColor: partnerInk, elevation: 0,
        titleTextStyle: TextStyle(color: partnerInk, fontSize: 21, fontWeight: FontWeight.w800)),
      cardTheme: CardThemeData(color: Colors.white, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE7EBF2)))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E6F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E6F0)))),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: partnerBrand, foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700))),
    ),
    home: Api.token == null ? const PartnerLogin() : const PartnerHome(),
  );
}