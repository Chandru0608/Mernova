import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'api.dart';

class PartnerToolsScreen extends StatefulWidget {
  const PartnerToolsScreen({super.key});
  @override State<PartnerToolsScreen> createState()=>_PartnerToolsScreenState();
}
class _PartnerToolsScreenState extends State<PartnerToolsScreen> {
  Map<String,dynamic>? earnings, performance, weather;
  final amount=TextEditingController(), litres=TextEditingController(), note=TextEditingController();
  bool busy=false; String message='';
  Future<Map<String,dynamic>> act(Future<Map<String,dynamic>> Function() f,{String success='Saved successfully'}) async {
    setState(()=>busy=true);
    try { final r=await f(); if(mounted)setState(()=>message=success); return r; }
    catch(e){if(mounted)setState(()=>message=e.toString()); rethrow;}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<Position> position() async {
    var p=await Geolocator.checkPermission();
    if(p==LocationPermission.denied)p=await Geolocator.requestPermission();
    if(p==LocationPermission.denied||p==LocationPermission.deniedForever)throw Exception('Location permission is required');
    return Geolocator.getCurrentPosition();
  }
  Future<void> refresh() async {
    final r=await Future.wait([Api.get('/features/partner/earnings'),Api.get('/features/partner/performance')]);
    if(mounted)setState(() {earnings=r[0];performance=r[1];});
  }
  @override void initState(){super.initState();refresh().catchError((e){if(mounted)setState(()=>message=e.toString());});}
  @override void dispose(){amount.dispose();litres.dispose();note.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Partner tools'),actions:[IconButton(onPressed:busy?null:() async {try{await refresh();if(mounted)setState(()=>message='Dashboard refreshed');}catch(e){if(mounted)setState(()=>message=e.toString());}},icon:const Icon(Icons.refresh))]),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('EARNINGS & PERFORMANCE',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1,color:Color(0xFF2456C5))),
      if(earnings!=null) Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Today · Net ₹${earnings!['today']?['net']??0}'),
        Text('Month · Net ₹${earnings!['month']?['net']??0}'),
        Text('Month deliveries · ${earnings!['month']?['deliveries']??0}'),
        Text('Fuel recorded this month · ₹${earnings!['month']?['fuelExpense']??0}')
      ]))),
      if(performance!=null) Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('${performance!['completed']} completed · ${performance!['cancelled']} cancelled',style:const TextStyle(fontWeight:FontWeight.w700)),
        Text(performance!['note']??'Performance details')
      ]))),
      const Divider(height:32),const Text('FUEL EXPENSE',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1,color:Color(0xFF2456C5))),
      TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),onChanged:(_)=>setState((){}),decoration:const InputDecoration(labelText:'Amount (₹)')),
      TextField(controller:litres,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Litres (optional)')),
      TextField(controller:note,decoration:const InputDecoration(labelText:'Note (optional)')),
      const SizedBox(height:8),
      FilledButton(onPressed:busy||(double.tryParse(amount.text)??0)<=0?null:() async {
        try {
          await act(()=>Api.post('/features/partner/fuel',{'amount':double.parse(amount.text),'litres':double.tryParse(litres.text),'note':note.text}),success:'Fuel expense saved');
          amount.clear();litres.clear();note.clear();await refresh();
        } catch (_) {}
      },child:const Text('Save fuel expense')),
      const Divider(height:32),const Text('SAFETY',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1,color:Color(0xFF2456C5))),
      FilledButton.tonal(onPressed:busy?null:() async {
        try {final p=await position();final r=await act(()=>Api.get('/features/partner/weather?latitude=${p.latitude}&longitude=${p.longitude}'),success:'Weather checked');if(mounted)setState(()=>weather=r);}
        catch (_) {}
      },child:const Text('Check local weather safety')),
      if(weather!=null) Card(child:ListTile(
        leading:Icon(weather!['alert']==true?Icons.warning_amber_rounded:Icons.wb_sunny_outlined,color:weather!['alert']==true?Colors.orange:Colors.green),
        title:Text(weather!['alert']==true?'Weather caution':'Weather conditions look normal'),
        subtitle:Text('Temperature ${weather!['current']?['temperature_2m']??'—'}°C · Wind ${weather!['current']?['wind_speed_10m']??'—'} km/h · Rain ${weather!['current']?['precipitation']??'—'} mm\n${weather!['message']??''}')
      )),
      FilledButton(style:FilledButton.styleFrom(backgroundColor:Colors.red),onPressed:busy?null:() async {
        final confirm=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Send emergency SOS?'),content:const Text('Your current GPS location will be sent to the QuickDeliver support event channel.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Send SOS'))]));
        if(confirm!=true)return;
        try {final p=await position();await act(()=>Api.post('/features/partner/sos',{'latitude':p.latitude,'longitude':p.longitude,'message':'Emergency assistance requested'}),success:'SOS event sent');}catch(_){}
      },child:const Text('Send SOS')),
      FilledButton.tonal(onPressed:busy?null:() async {try{await act(()=>Api.patch('/features/partner/availability',{'isAvailable':false}),success:'You are now unavailable');}catch(_){}},child:const Text('Start break / go unavailable')),
      FilledButton.tonal(onPressed:busy?null:() async {try{await act(()=>Api.patch('/features/partner/availability',{'isAvailable':true}),success:'You are available again');}catch(_){}},child:const Text('End break / go available')),
      if(message.isNotEmpty) Padding(padding:const EdgeInsets.only(top:16),child:Text(message,style:TextStyle(color:message.toLowerCase().contains('exception')?Colors.red:Colors.green,fontWeight:FontWeight.w600))),
      if(busy) const Padding(padding:EdgeInsets.all(12),child:LinearProgressIndicator()),
    ]));
}
