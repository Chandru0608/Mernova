import 'package:flutter/material.dart';
import 'api.dart';

const _green = Color(0xFF147D5A);
const _ink = Color(0xFF172B25);
const _muted = Color(0xFF718078);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final name=TextEditingController(), email=TextEditingController(), password=TextEditingController();
  bool register=false, busy=false, obscure=true;
  Future<void> submit() async {
    if(email.text.trim().isEmpty || password.text.isEmpty || (register && name.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Please complete all required fields.'))); return;
    }
    setState(()=>busy=true);
    try {
      final data=await Api.post(register?'/auth/register':'/auth/login', {
        if(register) 'name':name.text.trim(), 'email':email.text.trim(), 'password':password.text
      });
      if(data['token']!=null) await Api.saveToken(data['token']);
      if(!mounted)return;
      if(register && data['token']==null) {
        setState(()=>register=false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Account created. Please sign in.')));
      } else {
        Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomeScreen()));
      }
    } catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString()))); }
    finally { if(mounted)setState(()=>busy=false); }
  }
  @override void dispose(){name.dispose();email.dispose();password.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Container(height:88,width:88,decoration:BoxDecoration(color:_green.withOpacity(.1),borderRadius:BorderRadius.circular(28)),child:const Icon(Icons.delivery_dining_rounded,color:_green,size:52)),
    const SizedBox(height:26),Text(register?'Join QuickDeliver':'Good food. Right on time.',style:const TextStyle(fontSize:29,fontWeight:FontWeight.w800,color:_ink,height:1.15)),
    const SizedBox(height:9),Text(register?'Create your account and get your favourites delivered.':'Your neighbourhood favourites, delivered to your door.',style:const TextStyle(color:_muted,fontSize:15)),
    const SizedBox(height:30),
    if(register) ...[const Text('FULL NAME',style:TextStyle(fontSize:11,fontWeight:FontWeight.w800,color:_muted)),const SizedBox(height:7),TextField(controller:name,textCapitalization:TextCapitalization.words,decoration:const InputDecoration(hintText:'Your name')),const SizedBox(height:16)],
    const Text('EMAIL ADDRESS',style:TextStyle(fontSize:11,fontWeight:FontWeight.w800,color:_muted)),const SizedBox(height:7),
    TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(hintText:'you@example.com')),
    const SizedBox(height:16),const Text('PASSWORD',style:TextStyle(fontSize:11,fontWeight:FontWeight.w800,color:_muted)),const SizedBox(height:7),
    TextField(controller:password,obscureText:obscure,decoration:InputDecoration(hintText:'At least 8 characters',suffixIcon:IconButton(onPressed:()=>setState(()=>obscure=!obscure),icon:Icon(obscure?Icons.visibility_outlined:Icons.visibility_off_outlined)))),
    const SizedBox(height:24),FilledButton(onPressed:busy?null:submit,child:Text(busy?'Please wait…':register?'Create account':'Sign in')),
    const SizedBox(height:10),TextButton(onPressed:()=>setState(()=>register=!register),child:Text(register?'Already have an account? Sign in':'New to QuickDeliver? Create an account')),
  ]))))));
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  List products=[]; final cart=<String,int>{}; bool loading=true; String error=''; String filter='All';
  double get total {double sum=0;for(final p in products){sum+=(p['price'] as num).toDouble()*(cart[p['_id']]??0);}return sum;}
  int get count=>cart.values.fold(0,(a,b)=>a+b);
  List get visibleProducts=>products.where((p)=>filter=='All'||(p['type']??'').toString().toLowerCase()==filter.toLowerCase()).toList();
  @override void initState(){super.initState();load();}
  Future<void> load() async {
    setState(()=>loading=true);
    try{final d=await Api.get('/products');if(mounted)setState(()=>products=d['products']??[]);}
    catch(e){if(mounted)setState(()=>error=e.toString());}
    finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> checkout() async {
    final items=cart.entries.where((e)=>e.value>0).map((e)=>{'productId':e.key,'quantity':e.value}).toList();if(items.isEmpty)return;
    final address=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Where should we deliver?'),content:TextField(controller:address,maxLines:3,decoration:const InputDecoration(hintText:'House / flat, street, area, landmark')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Place order'))]));
    if(ok!=true||address.text.trim().isEmpty)return;
    try{final d=await Api.post('/orders/checkout',{'items':items,'address':address.text.trim()});if(!mounted)return;setState(()=>cart.clear());showDialog(context:context,builder:(ctx)=>AlertDialog(icon:const Icon(Icons.check_circle,color:_green,size:42),title:const Text('Order placed!'),content:Text(d['message']??'Your order has been received.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Done'))]));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  Future<void> logout() async {await Api.logout();if(!mounted)return;Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false);}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('QuickDeliver'),actions:[IconButton(tooltip:'My orders',onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const OrdersScreen())),icon:const Icon(Icons.receipt_long_outlined)),IconButton(tooltip:'Log out',onPressed:logout,icon:const Icon(Icons.logout))]),
    body:Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(18,8,18,16),child:Container(width:double.infinity,padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:_green,borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('YOUR DAY, DELIVERED.',style:TextStyle(color:Color(0xFFC8F0D9),fontSize:11,fontWeight:FontWeight.w800,letterSpacing:1.2)),
        const SizedBox(height:9),const Text('What are you craving?',style:TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w800)),
        const SizedBox(height:6),const Text('Fresh picks from stores around you.',style:TextStyle(color:Colors.white70,fontSize:13)),
        const SizedBox(height:16),Container(padding:const EdgeInsets.symmetric(horizontal:13,vertical:11),decoration:BoxDecoration(color:Colors.white.withOpacity(.15),borderRadius:BorderRadius.circular(13)),child:const Row(children:[Icon(Icons.bolt,color:Colors.white,size:18),SizedBox(width:8),Text('Easy ordering · Reliable delivery',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w600,fontSize:12))]))
      ]))),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Row(children:[const Expanded(child:Text('Explore products',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800,color:_ink))),IconButton(onPressed:load,icon:const Icon(Icons.refresh,color:_green))])),
      SizedBox(height:48,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:14),children:['All','Food','Grocery'].map((x)=>Padding(padding:const EdgeInsets.symmetric(horizontal:4),child:ChoiceChip(label:Text(x),selected:filter==x,onSelected:(_)=>setState(()=>filter=x),selectedColor:const Color(0xFFDDF1E6),labelStyle:TextStyle(color:filter==x?_green:_muted,fontWeight:FontWeight.w700)))).toList())),
      const SizedBox(height:8),
      Expanded(child:loading?const Center(child:CircularProgressIndicator()):error.isNotEmpty?Center(child:Padding(padding:const EdgeInsets.all(24),child:Text(error,textAlign:TextAlign.center))):RefreshIndicator(onRefresh:load,child:visibleProducts.isEmpty?ListView(children:const [SizedBox(height:90),Center(child:Text('No products in this category yet.'))]):GridView.builder(padding:const EdgeInsets.fromLTRB(16,6,16,18),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:.82),itemCount:visibleProducts.length,itemBuilder:(ctx,i){
        final p=visibleProducts[i];final id=p['_id'].toString();final q=cart[id]??0;final grocery=(p['type']??'').toString().toLowerCase()=='grocery';
        return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(child:Center(child:Container(width:76,height:76,decoration:BoxDecoration(color:grocery?const Color(0xFFEAF5E9):const Color(0xFFFFF1E5),borderRadius:BorderRadius.circular(23)),child:Icon(grocery?Icons.shopping_basket_rounded:Icons.lunch_dining_rounded,size:39,color:grocery?_green:const Color(0xFFCC7A32))))),
          Text(p['name']??'Product',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800,color:_ink)),
          const SizedBox(height:4),Text('₹${p['price']} · ${p['type']??'Product'}',style:const TextStyle(color:_muted,fontSize:12)),
          const SizedBox(height:9),Row(children:[Expanded(child:Text('₹${((p['price'] as num).toDouble()*q).toStringAsFixed(0)}',style:const TextStyle(fontWeight:FontWeight.w800,color:_green))),if(q==0)IconButton.filledTonal(onPressed:()=>setState(()=>cart[id]=1),icon:const Icon(Icons.add),visualDensity:VisualDensity.compact)else Row(children:[IconButton(onPressed:()=>setState(()=>cart[id]=q-1),icon:const Icon(Icons.remove_circle_outline),visualDensity:VisualDensity.compact),Text('$q',style:const TextStyle(fontWeight:FontWeight.w800)),IconButton(onPressed:()=>setState(()=>cart[id]=q+1),icon:const Icon(Icons.add_circle),visualDensity:VisualDensity.compact)])])
        ])));
      }))),
    ]),
    bottomNavigationBar:count==0?null:SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(16,8,16,12),child:FilledButton.icon(onPressed:checkout,icon:const Icon(Icons.shopping_bag_outlined),label:Text('View cart · $count items · ₹${total.toStringAsFixed(2)}')))),
  );
}

class OrdersScreen extends StatefulWidget {const OrdersScreen({super.key});@override State<OrdersScreen> createState()=>_OrdersScreenState();}
class _OrdersScreenState extends State<OrdersScreen>{
  List orders=[];bool loading=true;String error='';
  @override void initState(){super.initState();load();}
  Future<void> load()async{try{final d=await Api.get('/orders/my');if(mounted)setState(()=>orders=d['orders']??[]);}catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>loading=false);}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Your orders')),body:loading?const Center(child:CircularProgressIndicator()):error.isNotEmpty?Center(child:Text(error)):orders.isEmpty?const Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.receipt_long_outlined,size:54,color:_muted),SizedBox(height:12),Text('No orders yet',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700)),Text('Your orders will show up here.')])):RefreshIndicator(onRefresh:load,child:ListView.separated(padding:const EdgeInsets.all(16),itemCount:orders.length,separatorBuilder:(_,__)=>const SizedBox(height:12),itemBuilder:(ctx,i){final o=orders[i];final id=o['_id'].toString();return Card(child:Padding(padding:const EdgeInsets.all(17),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Expanded(child:Text('Order #${id.substring(id.length-6)}',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16))),Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:const Color(0xFFE5F3EA),borderRadius:BorderRadius.circular(30)),child:Text((o['status']??'placed').toString().replaceAll('_',' '),style:const TextStyle(color:_green,fontWeight:FontWeight.w700,fontSize:12)))]),
    const SizedBox(height:9),Text((o['items'] as List? ?? []).map((x)=>'${x['name']} × ${x['quantity']}').join(' · '),style:const TextStyle(color:_muted)),const SizedBox(height:9),Text('₹${o['total']}  ·  ${o['store']?['name']??'QuickDeliver store'}',style:const TextStyle(fontWeight:FontWeight.w700,color:_ink)),if((o['address']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.only(top:7),child:Text(o['address'],style:const TextStyle(color:_muted,fontSize:12)))
  ])));})));
}
