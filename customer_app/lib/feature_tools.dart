import 'package:flutter/material.dart';
import 'api.dart';

class CustomerToolsScreen extends StatefulWidget {
  const CustomerToolsScreen({super.key});
  @override State<CustomerToolsScreen> createState()=>_CustomerToolsScreenState();
}
class _CustomerToolsScreenState extends State<CustomerToolsScreen> {
  final orderId=TextEditingController(), invite=TextEditingController(), instruction=TextEditingController();
  Map<String,dynamic>? eta, compensation, reorder;
  bool available=true, busy=false;
  String message='';
  Future<void> run(Future<Map<String,dynamic>> Function() action) async {
    setState(()=>busy=true); try { final r=await action(); if(mounted)setState(()=>message=r.toString()); }
    catch(e){if(mounted)setState(()=>message=e.toString());} finally{if(mounted)setState(()=>busy=false);}
  }
  String get id=>orderId.text.trim();
  Future<void> loadEta() async {final r=await Api.get('/features/orders/$id/eta');setState(()=>eta=r);}
  Future<void> loadComp() async {final r=await Api.get('/features/orders/$id/compensation');setState(()=>compensation=r);}
  Future<void> loadReorder() async {final r=await Api.get('/features/orders/$id/reorder');setState(()=>reorder=r);}
  @override void dispose(){orderId.dispose();invite.dispose();instruction.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Order tools')),body:ListView(padding:const EdgeInsets.all(16),children:[
    const Text('CUSTOMER FEATURES',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1,color:Color(0xFF147D5A))),
    const SizedBox(height:8),const Text('Enter an order ID to check its live feature information.'),
    const SizedBox(height:12),TextField(controller:orderId,decoration:const InputDecoration(labelText:'Order ID',border:OutlineInputBorder())),
    const SizedBox(height:12),Wrap(spacing:8,runSpacing:8,children:[
      FilledButton.tonal(onPressed:busy||id.isEmpty?null:()=>run(() async {await loadEta();return eta!;}),child:const Text('Smart ETA')),
      FilledButton.tonal(onPressed:busy||id.isEmpty?null:()=>run(() async {await loadComp();return compensation!;}),child:const Text('Delay compensation')),
      FilledButton.tonal(onPressed:busy||id.isEmpty?null:()=>run(() async {await loadReorder();return reorder!;}),child:const Text('Reorder items')),
    ]),
    if(eta!=null) Card(child:ListTile(title:const Text('Estimated delivery'),subtitle:Text('${eta!['estimatedMinutes']} min · ${eta!['estimateType']}'))),
    if(compensation!=null) Card(child:ListTile(title:const Text('Delay compensation'),subtitle:Text(compensation!['eligible']==true?'Eligible · ${compensation!['compensationCode']??''}':compensation!['delayed']==true?'Delayed, not eligible':'No delay detected'))),
    if(reorder!=null) Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Available reorder items',style:TextStyle(fontWeight:FontWeight.bold)),...(reorder!['items'] as List? ?? []).map((x)=>Text('${x['name']} · ₹${x['price']}')),if((reorder!['unavailable'] as List? ?? []).isNotEmpty) Text('Unavailable: ${(reorder!['unavailable'] as List).join(', ')}')]))),
    const Divider(height:32),const Text('DELIVERY ACCESS',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1,color:Color(0xFF147D5A))),
    SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('I will be available for delivery'),value:available,onChanged:(v)=>setState(()=>available=v)),
    TextField(controller:instruction,maxLines:2,decoration:const InputDecoration(labelText:'Delivery instructions')),
    const SizedBox(height:8),FilledButton(onPressed:busy||id.isEmpty?null:()=>run(()=>Api.post('/features/orders/$id/customer-availability',{'available':available,'instructions':instruction.text.trim()})),child:const Text('Save availability & instructions')),
    const Divider(height:32),const Text('GROUP ORDER',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1,color:Color(0xFF147D5A))),
    TextField(controller:invite,decoration:const InputDecoration(labelText:'Group invite code')),
    const SizedBox(height:8),FilledButton.tonal(onPressed:busy||invite.text.trim().isEmpty?null:()=>run(()=>Api.post('/features/groups/join',{'inviteCode':invite.text.trim()})),child:const Text('Join a group')),
    if(message.isNotEmpty) Padding(padding:const EdgeInsets.only(top:16),child:SelectableText(message)),
    if(busy) const Padding(padding:EdgeInsets.all(12),child:LinearProgressIndicator()),
  ]));
}
