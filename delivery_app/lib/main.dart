import 'package:flutter/material.dart';
import 'api.dart';
import 'screens.dart';
void main() async { WidgetsFlutterBinding.ensureInitialized(); await Api.loadToken(); runApp(const DeliveryApp()); }
class DeliveryApp extends StatelessWidget {
 const DeliveryApp({super.key});
 @override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'QuickDeliver Partner',theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff1565c0)),useMaterial3:true),home:Api.token==null?const PartnerLogin():const PartnerHome());
}
