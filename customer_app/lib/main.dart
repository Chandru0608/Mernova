import 'package:flutter/material.dart';
import 'api.dart';
import 'screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.loadToken();
  runApp(const QuickDeliverApp());
}

class QuickDeliverApp extends StatelessWidget {
  const QuickDeliverApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'QuickDeliver',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff16803d)), useMaterial3:true),
    home: Api.token == null ? const LoginScreen() : const HomeScreen(),
  );
}
