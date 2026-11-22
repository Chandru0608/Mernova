import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'api.dart';

class CustomerToolsScreen extends StatefulWidget {
  const CustomerToolsScreen({super.key, this.initialOrderId=''});
  final String initialOrderId;
  @override State<CustomerToolsScreen> createState()=>_CustomerToolsScreenState();
}
class _CustomerToolsScreenState extends State<CustomerToolsScreen> {
  final orderId=TextEditingController(), invite=TextEditingController(), instruction=TextEditingController();
  Map<String,dynamic>? eta, compensation, reorder, handover;
  List stores=[]; String? selectedStoreId, groupId, inviteCode;
  bool available=true, busy=false;
  String message='';
  Map<String,dynamic>? groupDetails;
  final productId=TextEditingController(), quantity=TextEditingController(text:'1'), contribution=TextEditingController();
  @override void initState(){super.initState();orderId.text=widget.initialOrderId;loadStores();}
  Future<void> run(Future<Map<String,dynamic>> Function() action,{required String success}) async {
    setState(()=>busy=true);
    try { await action(); if(mounted)setState(()=>message=success); }
    catch(e){if(mounted)setState(()=>message=e.toString().replaceFirst('Exception: ','').replaceFirst('Exception:',''));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  String get id=>orderId.text.trim();
  Future<void> loadStores() async {try{final r=await Api.get('/stores');if(mounted)setState(()=>stores=r['stores']??[]);}catch(e){if(mounted)setState(()=>message=e.toString());}}
  Future<void> createGroup() async {if(selectedStoreId==null){setState(()=>message='Choose an open store first.');return;}await run(() async {final r=await Api.post('/features/groups',{'storeId':selectedStoreId});if(mounted){setState(() {groupId=r['groupId']?.toString();inviteCode=r['inviteCode']?.toString();});}await refreshGroup();return r;},success:'Group created. Share the invite code with friends.');}
  Future<void> loadHandover() async {final r=await Api.get('/features/orders/$id/handover-code');if(mounted)setState(()=>handover=r);}
  Future<void> refreshGroup() async {if(groupId==null)return;final r=await Api.get('/features/groups/$groupId');if(mounted)setState(()=>groupDetails=r['group'] as Map<String,dynamic>?);}
  Future<void> saveGroupItem() async {if(groupId==null)return;await run(() async {final r=await Api.put('/features/groups/$groupId/cart',{'items':[{'productId':productId.text.trim(),'quantity':int.tryParse(quantity.text)??1}]});await refreshGroup();return r;},success:'Your group cart saved.');}
  Future<void> recordContribution() async {if(groupId==null)return;await run(() async {final r=await Api.post('/features/groups/$groupId/contribution',{'amount':double.tryParse(contribution.text)??0});await refreshGroup();return r;},success:'Contribution recorded as pending. No payment was charged.');}
  Future<void> loadEta() async {final r=await Api.get('/features/orders/$id/eta');setState(()=>eta=r);}
  Future<void> loadComp() async {final r=await Api.get('/features/orders/$id/compensation');setState(()=>compensation=r);}
  Future<void> loadReorder() async {final r=await Api.get('/features/orders/$id/reorder');setState(()=>reorder=r);}
  @override void dispose(){orderId.dispose();invite.dispose();instruction.dispose();productId.dispose();quantity.dispose();contribution.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Order tools')),body:ListView(padding:const EdgeInsets.all(16),children:[
    const Text('CUSTOMER FEATURES',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1,color:Color(0xFF147D5A))),
    const SizedBox(height:8),const Text('Enter an order ID to check its live feature information.'),
    const SizedBox(height:12),TextField(controller:orderId,decoration:const InputDecoration(labelText:'Full order ID (24 characters)',hintText:'Open this from Your orders for accuracy',border:OutlineInputBorder())),
    const SizedBox(height:12),Wrap(spacing:8,runSpacing:8,children:[
      FilledButton.tonal(onPressed:busy||id.isEmpty?null:()=>run(() async {await loadEta();return eta!;},success:'ETA updated.'),child:const Text('Smart ETA')),
      FilledButton.tonal(onPressed:busy||id.isEmpty?null:()=>run(() async {await loadComp();return compensation!;},success:'Compensation status updated.'),child:const Text('Delay compensation')),
      FilledButton.tonal(onPressed:busy||id.isEmpty?null:()=>run(() async {await loadReorder();return reorder!;},success:'Reorder list updated.'),child:const Text('Reorder items')),
    ]),
    if(eta!=null) Card(child:ListTile(title:const Text('Estimated delivery'),subtitle:Text('${eta!['estimatedMinutes']} min · ${eta!['estimateType']}'))),
    if(compensation!=null) Card(child:ListTile(title:const Text('Delay compensation'),subtitle:Text(compensation!['eligible']==true?'Eligible · ${compensation!['compensationCode']??''}':compensation!['delayed']==true?'Delayed, not eligible':'No delay detected'))),
    if(reorder!=null) Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Available reorder items',style:TextStyle(fontWeight:FontWeight.bold)),...(reorder!['items'] as List? ?? []).map((x)=>Text('${x['name']} · ₹${x['price']}')),if((reorder!['unavailable'] as List? ?? []).isNotEmpty) Text('Unavailable: ${(reorder!['unavailable'] as List).join(', ')}')]))),
    if(handover!=null) Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[const Text('Show this QR code to your assigned delivery partner.'),QrImageView(data:'{"orderId":"${handover!['orderId']}","token":"${handover!['token']}"}',size:220),SelectableText('Order: ${handover!['orderId']}')] ))),
    if(id.isNotEmpty) OutlinedButton.icon(onPressed:busy?null:()=>run(() async {await loadHandover();return handover!;},success:'Handover QR ready.'),icon:const Icon(Icons.qr_code_2),label:const Text('Show handover QR')),
    const Divider(height:32),const Text('DELIVERY ACCESS',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1,color:Color(0xFF147D5A))),
    SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('I will be available for delivery'),value:available,onChanged:(v)=>setState(()=>available=v)),
    TextField(controller:instruction,maxLines:2,decoration:const InputDecoration(labelText:'Delivery instructions')),
    const SizedBox(height:8),FilledButton(onPressed:busy||id.isEmpty?null:()=>run(()=>Api.post('/features/orders/$id/customer-availability',{'available':available,'instructions':instruction.text.trim()}),success:'Availability and delivery instructions saved.'),child:const Text('Save availability & instructions')),
    const Divider(height:32),const Text('GROUP ORDER',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1,color:Color(0xFF147D5A))),
    if(stores.isEmpty) const Text('No open stores are available yet. Open a store in the store dashboard first.'),
    if(stores.isNotEmpty) DropdownButtonFormField<String>(value:selectedStoreId,decoration:const InputDecoration(labelText:'Choose a store'),items:stores.map<DropdownMenuItem<String>>((s)=>DropdownMenuItem(value:s['_id'].toString(),child:Text((s['name']??'Store').toString()))).toList(),onChanged:(v)=>setState(()=>selectedStoreId=v)),
    const SizedBox(height:8),FilledButton.icon(onPressed:busy||selectedStoreId==null?null:createGroup,icon:const Icon(Icons.group_add),label:const Text('Create group order')),
    if(groupId!=null&&inviteCode!=null) Card(child:ListTile(title:const Text('Group invitation created'),subtitle:SelectableText(inviteCode!),trailing:IconButton(icon:const Icon(Icons.copy),onPressed:()=>Clipboard.setData(ClipboardData(text:inviteCode!))))),
    if(groupId!=null) OutlinedButton(onPressed:busy?null:()=>run(() async {await refreshGroup();return groupDetails??{};},success:'Group refreshed.'),child:const Text('Refresh group details')),
    if(groupDetails!=null) Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('Group status: ${groupDetails!['status']}'),
      Text('Members: ${(groupDetails!['participants'] as List? ?? []).length}'),
      ...((groupDetails!['participants'] as List? ?? []).map((p)=>Text('${p['user']?['name']??'Member'} · ${(p['items'] as List? ?? []).length} items · ₹${p['contribution']??0} pending')))
    ]))),
    if(groupId!=null) const Text('Group cart (product ID from store catalogue)',style:TextStyle(fontWeight:FontWeight.w600)),
    if(groupId!=null) TextField(controller:productId,decoration:const InputDecoration(labelText:'Product ID')),
    if(groupId!=null) TextField(controller:quantity,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Quantity')),
    if(groupId!=null) FilledButton.tonal(onPressed:busy?null:saveGroupItem,child:const Text('Save my group cart')),
    if(groupId!=null) TextField(controller:contribution,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Planned contribution (₹)')),
    if(groupId!=null) OutlinedButton(onPressed:busy?null:recordContribution,child:const Text('Record planned contribution (not a payment)')),
    TextField(controller:invite,onChanged:(_)=>setState(()=>message=''),textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(labelText:'Group invite code')),
    const SizedBox(height:8),FilledButton.tonal(onPressed:busy||invite.text.trim().isEmpty?null:()=>run(() async {final r=await Api.post('/features/groups/join',{'inviteCode':invite.text.trim()});if(mounted)setState(()=>groupId=r['groupId']?.toString());await refreshGroup();return r;},success:'You joined the group. Checkout and payment are not enabled yet.'),child:const Text('Join a group')),
    if(message.isNotEmpty) Padding(padding:const EdgeInsets.only(top:16),child:Text(message,style:TextStyle(color:message.toLowerCase().contains('not found')||message.toLowerCase().contains('failed')||message.toLowerCase().contains('exception')?Colors.red:const Color(0xFF147D5A),fontWeight:FontWeight.w600))),
    if(busy) const Padding(padding:EdgeInsets.all(12),child:LinearProgressIndicator()),
  ]));
}
