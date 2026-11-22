import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'api.dart';

class PartnerToolsScreen extends StatefulWidget {
  const PartnerToolsScreen({super.key});
  @override State<PartnerToolsScreen> createState()=>_PartnerToolsScreenState();
}
class _PartnerToolsScreenState extends State<PartnerToolsScreen> {
  Map<String,dynamic>? earnings, performance;
  final amount=TextEditingController(), litres=TextEditingController(), note=TextEditingController();
  bool busy=false; String message='';
  Future<void> act(Future<Map<String,dynamic>> Function() f) async {setState(()=>busy=true);try{final r=await f();if(mounted)setState(()=>message=r.toString());}catch(e){if(mounted)setState(()=>message=e.toString());}finally{if(mounted)setState(()=>busy=false);}}
  Future<Position> position() async {var p=await Geolocator.checkPermission();if(p==LocationPermission.denied)p=await Geolocator.requestPermission();if(p==LocationPermission.denied||p==LocationPermission.deniedForever)throw Exception('Location permission is required');return Geolocator.getCurrentPosition();}
  Future<void> refresh() async {final r=await Future.wait([Api.get('/features/partner/earnings'),Api.get('/features/partner/performance')]);if(mounted){setState(() {earnings=r[0];performance=r[1];});}}
  @override void initState(){super.initState();refresh().catchError((e){if(mounted)setState(()=>message=e.toString());});}
  @override void dispose(){amount.dispose();litres.dispose();note.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Partner tools'),actions:[IconButton(onPressed:busy?null:()=>act(() async {await refresh();return {'refreshed':true};}),icon:const Icon(Icons.refresh))]),body:ListView(padding:const EdgeInsets.all(16),children:[
    const Text('EARNINGS & PERFORMANCE',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1,color:Color(0xFF2456C5))),
    if(earnings!=null) Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Today · Net ₹${earnings!['today']?['net']??0}'),Text('Month · Net ₹${earnings!['month']?['net']??0}'),Text('Month deliveries · ${earnings!['month']?['deliveries']??0}')]))),
    if(performance!=null) Card(child:ListTile(title:Text('${performance!['completed']} completed · ${performance!['cancelled']} cancelled'),subtitle:Text('Average delivery: ${performance!['averageDeliveryMinutes']??'—'} min · ${performance!['note']??''}'))),
    const Divider(height:32),const Text('FUEL EXPENSE',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1,color:Color(0xFF2456C5))),
    TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Amount (₹)')),
    TextField(controller:litres,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Litres (optional)')),
    TextField(controller:note,decoration:const InputDecoration(labelText:'Note (optional)')),
    const SizedBox(height:8),FilledButton(onPressed:busy||(double.tryParse(amount.text)??0)<=0?null:()=>act(()=>Api.post('/features/partner/fuel',{'amount':double.parse(amount.text),'litres':double.tryParse(litres.text),'note':note.text})),child:const Text('Save fuel expense')),
    const Divider(height:32),const Text('SAFETY',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1,color:Color(0xFF2456C5))),
    FilledButton.tonal(onPressed:busy?null:()=>act(() async {final p=await position();return Api.get('/features/partner/weather?latitude=${p.latitude}&longitude=${p.longitude}');}),child:const Text('Check local weather safety')),
    FilledButton(style:FilledButton.styleFrom(backgroundColor:Colors.red),onPressed:busy?null:()=>act(() async {final p=await position();return Api.post('/features/partner/sos',{'latitude':p.latitude,'longitude':p.longitude,'message':'Emergency assistance requested'});}),child:const Text('Send SOS')),
    FilledButton.tonal(onPressed:busy?null:()=>act(()=>Api.patch('/features/partner/availability',{'isAvailable':false})),child:const Text('Start break / go unavailable')),
    FilledButton.tonal(onPressed:busy?null:()=>act(()=>Api.patch('/features/partner/availability',{'isAvailable':true})),child:const Text('End break / go available')),
    if(message.isNotEmpty) Padding(padding:const EdgeInsets.only(top:16),child:SelectableText(message)),
    if(busy) const Padding(padding:EdgeInsets.all(12),child:LinearProgressIndicator()),
  ]));
}
