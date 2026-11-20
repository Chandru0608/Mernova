import 'package:flutter/material.dart';
import 'api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState()=>_LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final name=TextEditingController(), email=TextEditingController(), password=TextEditingController();
  bool register=false, busy=false;
  Future<void> submit() async {
    setState(()=>busy=true);
    try {
      final data = await Api.post(register?'/auth/register':'/auth/login', {
        if(register) 'name':name.text.trim(),
        'email':email.text.trim(),'password':password.text
      });
      if(data['token']!=null) await Api.saveToken(data['token']);
      if(!mounted)return;
      if(register && data['token']==null) {
        setState(()=>register=false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Registered. Please log in.')));
      } else {
        Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomeScreen()));
      }
    } catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString()))); }
    finally { if(mounted)setState(()=>busy=false); }
  }
  @override Widget build(BuildContext context)=>Scaffold(body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:420),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Icon(Icons.delivery_dining,size:76,color:Color(0xff16803d)),const Text('QuickDeliver',textAlign:TextAlign.center,style:TextStyle(fontSize:30,fontWeight:FontWeight.bold)),
    Text(register?'Create customer account':'Welcome back',textAlign:TextAlign.center),
    const SizedBox(height:25),
    if(register) TextField(controller:name,decoration:const InputDecoration(labelText:'Full name',border:OutlineInputBorder())),
    const SizedBox(height:12),TextField(controller:email,decoration:const InputDecoration(labelText:'Email',border:OutlineInputBorder())),
    const SizedBox(height:12),TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Password (min 8 characters)',border:OutlineInputBorder())),
    const SizedBox(height:18),FilledButton(onPressed:busy?null:submit,child:Text(busy?'Please wait':register?'Register':'Login')),
    TextButton(onPressed:()=>setState(()=>register=!register),child:Text(register?'Already registered? Login':'Create an account'))
  ])))));
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  List products=[]; final cart=<String,int>{}; bool loading=true; String error='';
  double get total {
    double sum=0;
    for(final p in products){final q=cart[p['_id']]??0;sum+=(p['price'] as num).toDouble()*q;}
    return sum;
  }
  @override void initState(){super.initState();load();}
  Future<void> load() async {
    try { final d=await Api.get('/products'); if(mounted)setState(()=>products=d['products']??[]); }
    catch(e){if(mounted)setState(()=>error=e.toString());}
    finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> checkout() async {
    final items=cart.entries.where((e)=>e.value>0).map((e)=>{'productId':e.key,'quantity':e.value}).toList();
    if(items.isEmpty)return;
    final address=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Delivery address'),content:TextField(controller:address,decoration:const InputDecoration(hintText:'Enter full address')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Place order'))]));
    if(ok!=true || address.text.trim().isEmpty)return;
    try {
      final d=await Api.post('/orders/checkout',{'items':items,'address':address.text.trim()});
      setState(()=>cart.clear());
      if(mounted)showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Order placed'),content:Text(d['message']??'Success'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('OK'))]));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  Future<void> logout() async {await Api.logout();if(!mounted)return;Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false);}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('QuickDeliver')),drawer:Drawer(child:ListView(children:[const DrawerHeader(child:Text('QuickDeliver',style:TextStyle(fontSize:24))),ListTile(leading:const Icon(Icons.receipt_long),title:const Text('My orders'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const OrdersScreen()))),ListTile(leading:const Icon(Icons.logout),title:const Text('Logout'),onTap:logout)])),body:loading?const Center(child:CircularProgressIndicator()):Column(children:[
    Padding(padding:const EdgeInsets.all(16),child:Text(error.isEmpty?'Fresh food and groceries delivered to you':error)),
    Expanded(child:RefreshIndicator(onRefresh:load,child:products.isEmpty?ListView(children:const [SizedBox(height:120),Center(child:Text('No products available yet'))]):ListView.builder(itemCount:products.length,itemBuilder:(ctx,i){final p=products[i];final q=cart[p['_id']]??0;return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:ListTile(leading:const CircleAvatar(child:Icon(Icons.shopping_basket)),title:Text(p['name']??'Product'),subtitle:Text('₹${p['price']} · ${p['type']??''}'),trailing:Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:q>0?()=>setState(()=>cart[p['_id']]=q-1):null,icon:const Icon(Icons.remove)),Text('$q'),IconButton(onPressed:()=>setState(()=>cart[p['_id']]=q+1),icon:const Icon(Icons.add))])));}))),
    SafeArea(child:Container(padding:const EdgeInsets.all(12),width:double.infinity,child:FilledButton(onPressed:cart.isEmpty?null:checkout,child:Text('Checkout · ₹${total.toStringAsFixed(2)}'))))
  ]));
}

class OrdersScreen extends StatefulWidget {const OrdersScreen({super.key});@override State<OrdersScreen> createState()=>_OrdersScreenState();}
class _OrdersScreenState extends State<OrdersScreen>{
  List orders=[];bool loading=true;
  @override void initState(){super.initState();Api.get('/orders/my').then((d){if(mounted)setState(()=>orders=d['orders']??[]);}).catchError((_){}).whenComplete(()=>setState(()=>loading=false));}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('My orders')),body:loading?const Center(child:CircularProgressIndicator()):ListView(children:orders.map((o)=>ListTile(title:Text('Order #${o['_id'].toString().substring(o['_id'].toString().length-6)}'),subtitle:Text('${o['status']} · ₹${o['total']}'))).toList()));
}
