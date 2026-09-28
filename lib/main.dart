import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() => runApp(const Nova());

const orange = Color(0xFFFF5A36);
const ink = Color(0xFF151922);
const muted = Color(0xFF747A86);

class R {
  final String name, type, address, image, source;
  final double rating, lat, lng;
  final int reviews;
  final List<String> branches;
  final List<M> menu;
  const R(this.name, this.type, this.address, this.image, this.source, this.rating, this.reviews, this.lat, this.lng, this.branches, this.menu);
}
class M {
  final String name, desc, image;
  final double price;
  const M(this.name, this.desc, this.price, this.image);
}
class Line {
  final R r; final M m; int qty;
  Line(this.r, this.m, [this.qty = 1]);
}

const burger = 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=85';
const pizza = 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=900&q=85';
const chicken = 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=900&q=85';
const dessert = 'https://images.unsplash.com/photo-1551024506-0bccd828d307?auto=format&fit=crop&w=900&q=85';

final data = <R>[
  R('دجاج كنتاكي','فراخ مقلية','40 شارع الجمهورية، أمام بوابة جامعة المنصورة','https://s3-eu-west-1.amazonaws.com/elmenusv5-stg/Normal/dc5de1f8-2580-11e8-add5-0242ac110011.jpg','المنيوز',4.7,171,31.0429,31.3564,[
    'حي الجامعة — طريق عبد الرحمن بن عوف، بجوار القرية الأولمبية','توريل — شارع قناة السويس، برج جرين بلازا','جامعة المنصورة — 40 شارع الجمهورية، أمام بوابة الجامعة'
  ],[
    M('وجبة دجاج','دجاج مقرمش مع البطاطس والمشروب',210,chicken),M('تشيكن ساندوتش','ساندوتش دجاج مقرمش',135,chicken),M('بطاطس','بطاطس مقلية ذهبية',65,chicken)
  ]),
  R('ماكدونالدز','برجر','40 شارع الجمهورية، بعد مدخل الجامعة','https://s3-eu-west-1.amazonaws.com/elmenusv5-stg/Normal/1c39ac78-9b6c-4aec-a40a-b867fd1d95f9.jpg','المنيوز',4.8,3005,31.0430,31.3560,[
    'جديلة — 109 طريق قناة السويس','شارع الجيش — بجوار بنزينة شيل أوت','جامعة المنصورة — 40 شارع الجمهورية، بعد مدخل الجامعة'
  ],[
    M('بيج ماك','البرجر الكلاسيكي الشهير',180,burger),M('ماك تشيكن','ساندوتش دجاج مقرمش',145,chicken),M('بطاطس مقلية','بطاطس ماكدونالدز',65,chicken)
  ]),
  R('بازوكا','فراخ مقلية','شارع الجيش أمام استاد المنصورة شيل أوت','https://s3-eu-west-1.amazonaws.com/elmenusv5-stg/Normal/63a9b1bd-370e-48c4-a1ae-a8803fe1af47.jpg','المنيوز',4.6,895,31.0470,31.3544,[
    'شارع الجيش — أمام استاد المنصورة شيل أوت','جامعة المنصورة — شارع الجمهورية، أمام مركز طب وجراحة العيون'
  ],[
    M('وجبة بازوكا سنايبر','3 قطع دجاج + بطاطس + خبز + كول سلو',210,chicken),M('ريزو بقطع الدجاج','صوص حار أو باربيكيو',95,chicken),M('ساندوتش تشيكن رانش','دجاج مقرمش ورانش وموتزاريلا',145,chicken),M('أصابع الموتزاريلا','3 قطع مع صوص',50,chicken)
  ]),
  R('كاتشاب','برجر وبيتزا','44 شارع جيهان، أمام الدفاع المدني، حي الجامعة',burger,'المنيوز',4.5,44,31.0450,31.3509,[
    '44 شارع جيهان، أمام الدفاع المدني، حي الجامعة'
  ],[
    M('Super Crunchy Sandwich','ساندوتش كرانشي',110,burger),M('Julian Chicken Pizza','بيتزا دجاج',110,pizza),M('Crunchy Pizza','بيتزا كرانشي',110,pizza),M('Mix Grill Meal','أرز وبطاطس وكول سلو وبيبسي',210,chicken),M('Shrimp Pizza','بيتزا جمبري',155,pizza)
  ]),
  R('تيكتس','ساندويتشات وبرجر','المنصورة — فرع واحد',burger,'EGMenus',4.5,1000,31.0438,31.3508,[
    'المنصورة — فرع واحد'
  ],[
    M('تيكتس فرست كلاس','خس وخيار مخلل وجبنة سويسري ومايونيز',75,burger),M('مستر جاك','روكا وخس وسموك بيف وجبنة وصوص',85,burger),M('سويت رينجز','مربى توت وجبنة وأناناس وبصل مقلي',95,burger),M('تشيزي بارتي','موزاريلا وأصابع موتزاريلا وصوص',90,burger),M('عرض بيتزا مارجريتا وسط','بيتزا مارجريتا وسط',105,pizza)
  ]),
  R('مطعم و كافية ستريو','برجر وحلويات','شارع الجمهورية، أمام جامعة المنصورة (دليفري فقط)','https://s3-eu-west-1.amazonaws.com/elmenusv5-stg/Normal/100466e5-aefc-473a-8381-281b84a0d436.jpg','المنيوز',4.6,462,31.0421,31.3572,[
    'شارع الجمهورية، أمام جامعة المنصورة (دليفري فقط)'
  ],[
    M('برجر ستريو','برجر على طريقة ستريو',165,burger),M('وجبة تشيكن','وجبة دجاج مع إضافات',190,chicken),M('كيك شوكولاتة','حلوى شوكولاتة',110,dessert)
  ]),
];

class Nova extends StatefulWidget {
  const Nova({super.key});
  @override State<Nova> createState() => _NovaState();
}
class _NovaState extends State<Nova> {
  bool dark = false;
  @override Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:false,
      title:'نوفا ديليفري',
      theme:ThemeData(
        useMaterial3:true,
        colorScheme:ColorScheme.fromSeed(seedColor:orange,brightness:dark?Brightness.dark:Brightness.light),
        scaffoldBackgroundColor:dark?const Color(0xFF101114):const Color(0xFFF8F7F4),
        cardTheme:CardThemeData(elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22))),
      ),
      home:Shell(dark:dark,onDark:(v)=>setState(()=>dark=v)),
    );
  }
}

class Shell extends StatefulWidget {
  final bool dark; final ValueChanged<bool> onDark;
  const Shell({super.key,required this.dark,required this.onDark});
  @override State<Shell> createState()=>_ShellState();
}
class _ShellState extends State<Shell> {
  int tab=0; final cart=<Line>[]; final fav=<String>{};
  double get total=>cart.fold(0,(s,x)=>s+x.m.price*x.qty);
  int get count=>cart.fold(0,(s,x)=>s+x.qty);
  void add(R r,M m){setState((){final i=cart.indexWhere((x)=>x.r.name==r.name&&x.m.name==m.name);if(i>=0){cart[i].qty++;}else{cart.add(Line(r,m));}});}
  void sub(Line x)=>setState((){if(x.qty>1){x.qty--;}else{cart.remove(x);}});
  void open(R r)=>Navigator.push(context,MaterialPageRoute(builder:(_)=>RestaurantPage(r:r,fav:fav.contains(r.name),onFav:()=>setState((){if(!fav.add(r.name))fav.remove(r.name);}),onAdd:add)));
  @override Widget build(BuildContext context){
    final pages=[Home(onOpen:open,onMap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MapPage()))),const SearchPage(),const OrdersPage(),CartPage(cart:cart,total:total,onAdd:(x)=>add(x.r,x.m),onSub:sub),ProfilePage(dark:widget.dark,onDark:widget.onDark,onMap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MapPage())))];
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      body:SafeArea(child:IndexedStack(index:tab,children:pages)),
      bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[
        NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded),label:'الرئيسية'),
        NavigationDestination(icon:Icon(Icons.search_rounded),label:'اكتشف'),
        NavigationDestination(icon:Icon(Icons.receipt_long_outlined),label:'طلباتي'),
        NavigationDestination(icon:Icon(Icons.shopping_bag_outlined),label:'السلة'),
        NavigationDestination(icon:Icon(Icons.person_outline),label:'حسابي'),
      ]),
      floatingActionButton:count==0?null:FloatingActionButton.extended(backgroundColor:orange,foregroundColor:Colors.white,onPressed:()=>setState(()=>tab=3),icon:const Icon(Icons.shopping_bag_outlined),label:Text(count.toString()+' • '+total.toStringAsFixed(0)+' ج.م')),
    ));
  }
}

class Home extends StatelessWidget {
  final ValueChanged<R> onOpen; final VoidCallback onMap;
  const Home({super.key,required this.onOpen,required this.onMap});
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(18,10,18,110),children:[
    Row(children:[
      Container(width:48,height:48,decoration:BoxDecoration(color:orange,borderRadius:BorderRadius.circular(15)),child:const Icon(Icons.delivery_dining_rounded,color:Colors.white,size:29)),
      const SizedBox(width:12),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('نوفا ديليفري',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900)),Text('أكلك الحقيقي… في طريقه ليك 👋',style:TextStyle(color:muted,fontSize:12))])),
      IconButton.filledTonal(onPressed:()=>showNotifications(context),icon:const Icon(Icons.notifications_none_rounded)),
    ]),
    const SizedBox(height:16),
    InkWell(onTap:onMap,borderRadius:BorderRadius.circular(18),child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(18)),child:const Row(children:[Icon(Icons.location_on_rounded,color:orange),SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('عنوان التوصيل',style:TextStyle(color:muted,fontSize:10)),Text('المنصورة • اختر موقعك على الخريطة',style:TextStyle(fontWeight:FontWeight.bold))])),Icon(Icons.chevron_left_rounded)]))),
    const SizedBox(height:18),
    Container(height:185,padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFFFF4D2E),Color(0xFFFF8B55)]),borderRadius:BorderRadius.circular(28),boxShadow:[BoxShadow(color:Color(0x40FF5A36),blurRadius:25,offset:Offset(0,12))]),child:Stack(children:[
      const Positioned(right:-35,top:-45,child:Icon(Icons.local_shipping_rounded,color:Colors.white24,size:180)),
      const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('كل اللي نفسك فيه…',style:TextStyle(color:Colors.white70)),SizedBox(height:5),Text('يوصل لبابك بسرعة 🚀',style:TextStyle(color:Colors.white,fontSize:25,fontWeight:FontWeight.w900)),SizedBox(height:8),Text('مطاعم حقيقية • فروع حقيقية • بيانات موثقة',style:TextStyle(color:Colors.white,fontSize:11))]),
      Positioned(bottom:0,left:0,child:FilledButton.tonal(onPressed:onMap,child:const Text('افتح الخريطة'))),
    ])),
    const SizedBox(height:23),title('اختار مزاجك','عرض الكل'),const SizedBox(height:11),
    SizedBox(height:92,child:ListView(scrollDirection:Axis.horizontal,children:const[Cat('🍔','برجر'),Cat('🍗','فراخ'),Cat('🍕','بيتزا'),Cat('🍰','حلويات'),Cat('🥤','مشروبات'),Cat('🥗','صحي')])),
    const SizedBox(height:22),title('مطاعم حقيقية حولك','الخريطة'),const SizedBox(height:12),
    ...data.map((r)=>Padding(padding:const EdgeInsets.only(bottom:14),child:CardR(r:r,onTap:()=>onOpen(r)))),
    const SizedBox(height:4),const Text('المصادر: المنيوز و EGMenus • تحقق من البيانات: سبتمبر 2026',style:TextStyle(color:muted,fontSize:10)),
  ]);
}

Widget title(String a,String b)=>Row(children:[Expanded(child:Text(a,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900))),Text(b,style:const TextStyle(color:orange,fontSize:12,fontWeight:FontWeight.bold))]);

class Cat extends StatelessWidget {
  final String e,n; const Cat(this.e,this.n,{super.key});
  @override Widget build(BuildContext c)=>Container(width:82,margin:const EdgeInsets.only(left:10),decoration:BoxDecoration(color:Theme.of(c).colorScheme.surface,borderRadius:BorderRadius.circular(20)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(e,style:const TextStyle(fontSize:30)),const SizedBox(height:5),Text(n,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:12))]));
}

class CardR extends StatelessWidget {
  final R r; final VoidCallback onTap; const CardR({super.key,required this.r,required this.onTap});
  @override Widget build(BuildContext c)=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(24),child:Container(decoration:BoxDecoration(color:Theme.of(c).colorScheme.surface,borderRadius:BorderRadius.circular(24),boxShadow:const[BoxShadow(color:Color(0x0C000000),blurRadius:18,offset:Offset(0,7))]),child:Column(children:[
    Stack(children:[
      ClipRRect(borderRadius:const BorderRadius.vertical(top:Radius.circular(24)),child:Image.network(r.image,height:155,width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(height:155,color:const Color(0xFFEDEAE4),child:const Icon(Icons.restaurant_rounded,size:55,color:orange)))),
      Positioned(top:12,right:12,child:Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:6),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.94),borderRadius:BorderRadius.circular(12)),child:Row(children:[const Icon(Icons.star_rounded,color:Color(0xFFFFB300),size:17),const SizedBox(width:3),Text(r.rating.toString(),style:const TextStyle(fontWeight:FontWeight.w900))]))),
      Positioned(bottom:10,left:10,child:Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:6),decoration:BoxDecoration(color:ink.withValues(alpha:.84),borderRadius:BorderRadius.circular(10)),child:const Text('متاح للتوصيل',style:TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.bold)))),
    ]),
    Padding(padding:const EdgeInsets.all(14),child:Column(children:[
      Row(children:[Expanded(child:Text(r.name,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900))),Text(r.reviews.toString()+' تقييم',style:const TextStyle(color:muted,fontSize:10))]),
      const SizedBox(height:6),Row(children:[const Icon(Icons.restaurant_menu,size:15,color:muted),const SizedBox(width:5),Text(r.type,style:const TextStyle(color:muted,fontSize:11)),const Spacer(),const Icon(Icons.access_time,size:15,color:muted),const SizedBox(width:4),Text('توصيل سريع',style:const TextStyle(color:muted,fontSize:11))]),
      const SizedBox(height:7),Row(children:[const Icon(Icons.location_on_outlined,size:15,color:orange),const SizedBox(width:4),Expanded(child:Text(r.address,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:muted,fontSize:10)))]),
    ])),
  ]));
}

class RestaurantPage extends StatelessWidget {
  final R r; final bool fav; final VoidCallback onFav; final void Function(R,M) onAdd;
  const RestaurantPage({super.key,required this.r,required this.fav,required this.onFav,required this.onAdd});
  @override Widget build(BuildContext c)=>Scaffold(body:CustomScrollView(slivers:[
    SliverAppBar(expandedHeight:260,pinned:true,backgroundColor:ink,actions:[IconButton(onPressed:onFav,icon:Icon(fav?Icons.favorite:Icons.favorite_border,color:Colors.white))],flexibleSpace:FlexibleSpaceBar(title:Text(r.name,style:const TextStyle(fontWeight:FontWeight.w900)),background:Stack(fit:StackFit.expand,children:[Image.network(r.image,fit:BoxFit.cover),const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Color(0xD9000000)])))]))),
    SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Icon(Icons.star_rounded,color:Color(0xFFFFB300)),const SizedBox(width:4),Text(r.rating.toString(),style:const TextStyle(fontWeight:FontWeight.w900)),Text(' • '+r.reviews.toString()+' تقييم',style:const TextStyle(color:muted)),const Spacer(),FilledButton.tonalIcon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>MapPage(restaurant:r))),icon:const Icon(Icons.map_outlined),label:const Text('الخريطة'))]),
      const SizedBox(height:12),Text(r.address,style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:5),Text(r.hours+' • '+r.phone,style:const TextStyle(color:muted,fontSize:12)),
      const SizedBox(height:20),const Text('الفروع الحقيقية',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:9),
      ...r.branches.map((b)=>Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:Theme.of(c).colorScheme.surface,borderRadius:BorderRadius.circular(16)),child:Row(children:[const Icon(Icons.storefront_outlined,color:orange),const SizedBox(width:9),Expanded(child:Text(b,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600)))]))),
      const SizedBox(height:16),Row(children:[const Expanded(child:Text('المنيو',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900))),Chip(label:Text(r.source),avatar:const Icon(Icons.verified_rounded,size:15,color:orange))]),const SizedBox(height:10),
      ...r.menu.map((m)=>MenuCard(m:m,onAdd:()=>onAdd(r,m))),
    ]))),
  ]));
}

class MenuCard extends StatelessWidget {
  final M m; final VoidCallback onAdd; const MenuCard({super.key,required this.m,required this.onAdd});
  @override Widget build(BuildContext c)=>Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:Theme.of(c).colorScheme.surface,borderRadius:BorderRadius.circular(20)),child:Row(children:[
    ClipRRect(borderRadius:BorderRadius.circular(15),child:Image.network(m.image,width:88,height:88,fit:BoxFit.cover)),
    const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(m.name,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:15)),const SizedBox(height:5),Text(m.desc,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:muted,fontSize:11)),const SizedBox(height:7),Text(m.price.toStringAsFixed(0)+' ج.م',style:const TextStyle(color:orange,fontWeight:FontWeight.w900,fontSize:15))])),IconButton.filled(onPressed:onAdd,icon:const Icon(Icons.add_rounded))
  ]));
}

class SearchPage extends StatefulWidget{const SearchPage({super.key});@override State<SearchPage> createState()=>_SearchPageState();}
class _SearchPageState extends State<SearchPage>{String q='';@override Widget build(BuildContext c){final list=data.where((r)=>q.isEmpty||r.name.contains(q)||r.type.contains(q)).toList();return ListView(padding:const EdgeInsets.fromLTRB(18,18,18,100),children:[const Text('اكتشف',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:6),const Text('مطاعم ومنيوهات حقيقية حولك',style:TextStyle(color:muted)),const SizedBox(height:18),TextField(onChanged:(v)=>setState(()=>q=v),decoration:InputDecoration(hintText:'ابحث باسم المطعم أو النوع…',prefixIcon:const Icon(Icons.search_rounded),suffixIcon:const Icon(Icons.tune_rounded),filled:true,fillColor:Theme.of(c).colorScheme.surface,border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none))),const SizedBox(height:18),...list.map((r)=>Padding(padding:const EdgeInsets.only(bottom:14),child:CardR(r:r,onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>RestaurantPage(r:r,fav:false,onFav:(){},onAdd:(_,__){})))))]);}}

class OrdersPage extends StatelessWidget{const OrdersPage({super.key});@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(18),children:[const Text('طلباتي',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:18),const OTile('NV-2841','دجاج كنتاكي','السائق في الطريق إليك',true),const OTile('NV-2819','بازوكا','تم التسليم • أمس',false),const OTile('NV-2772','تيكتس','تم التسليم • 18 سبتمبر',false)]);}
class OTile extends StatelessWidget{final String id,shop,status;final bool active;const OTile(this.id,this.shop,this.status,this.active,{super.key});@override Widget build(BuildContext c){final col=active?orange:Colors.green;return Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Theme.of(c).colorScheme.surface,borderRadius:BorderRadius.circular(20)),child:Column(children:[Row(children:[CircleAvatar(backgroundColor:col.withValues(alpha:.12),child:Icon(active?Icons.delivery_dining:Icons.check,color:col)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(shop,style:const TextStyle(fontWeight:FontWeight.w900)),Text('#'+id,style:const TextStyle(color:muted,fontSize:11))])),Icon(active?Icons.location_on:Icons.check_circle,color:col)]),const SizedBox(height:12),Row(children:[Icon(active?Icons.bolt:Icons.done_all,color:col,size:18),const SizedBox(width:7),Text(status,style:TextStyle(color:col,fontWeight:FontWeight.w800,fontSize:12))]),if(active)...[const SizedBox(height:12),const LinearProgressIndicator(value:.72,color:orange,minHeight:7),const SizedBox(height:8),const Align(alignment:Alignment.centerRight,child:Text('متوقع الوصول خلال 18 دقيقة',style:TextStyle(color:muted,fontSize:11)))] ]);}}

class CartPage extends StatelessWidget{final List<Line> cart;final double total;final void Function(Line) onAdd,onSub;const CartPage({super.key,required this.cart,required this.total,required this.onAdd,required this.onSub});@override Widget build(BuildContext c){if(cart.isEmpty)return const Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.shopping_bag_outlined,size:80,color:orange),SizedBox(height:15),Text('السلة لسه فاضية',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),Text('اختار أكلك المفضل وابدأ طلبك',style:TextStyle(color:muted))]));return ListView(padding:const EdgeInsets.fromLTRB(18,18,18,100),children:[const Text('السلة',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:18),...cart.map((x)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:Theme.of(c).colorScheme.surface,borderRadius:BorderRadius.circular(20)),child:Row(children:[ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.network(x.m.image,width:72,height:72,fit:BoxFit.cover)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(x.m.name,style:const TextStyle(fontWeight:FontWeight.w900)),Text(x.r.name,style:const TextStyle(color:muted,fontSize:11)),Text((x.m.price*x.qty).toStringAsFixed(0)+' ج.م',style:const TextStyle(color:orange,fontWeight:FontWeight.w900))])),Row(children:[IconButton(onPressed:()=>onSub(x),icon:const Icon(Icons.remove_circle_outline)),Text(x.qty.toString()),IconButton(onPressed:()=>onAdd(x),icon:const Icon(Icons.add_circle_outline,color:orange))])])),line('المجموع',total),line('التوصيل',25),line('الخدمة',8),const Divider(height:28),line('الإجمالي',total+33,bold:true),const SizedBox(height:14),FilledButton(onPressed:()=>checkout(c,total+33),style:FilledButton.styleFrom(backgroundColor:orange,minimumSize:const Size.fromHeight(55)),child:const Text('إتمام الطلب'))];}}
Widget line(String s,double v,{bool bold=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Expanded(child:Text(s,style:TextStyle(fontWeight:bold?FontWeight.w900:FontWeight.w500))),Text(v.toStringAsFixed(0)+' ج.م',style:TextStyle(fontWeight:FontWeight.w900,color:bold?orange:null))]));

class ProfilePage extends StatelessWidget{final bool dark;final ValueChanged<bool> onDark;final VoidCallback onMap;const ProfilePage({super.key,required this.dark,required this.onDark,required this.onMap});@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.fromLTRB(18,18,18,100),children:[Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:ink,borderRadius:BorderRadius.circular(26)),child:const Row(children:[CircleAvatar(radius:32,backgroundColor:orange,child:Icon(Icons.person,color:Colors.white,size:32)),SizedBox(width:14),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('نوفا ديليفري',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.w900)),Text('حساب العميل',style:TextStyle(color:Colors.white70,fontSize:12))])])),const SizedBox(height:18),const Text('الإعدادات والخدمات',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:8),st(c,Icons.location_on_outlined,'العناوين والخريطة','حدد موقعك وفروع المطاعم',onMap),st(c,Icons.credit_card,'طرق الدفع','كاش • بطاقة • محفظة',(){}),st(c,Icons.favorite_border,'المفضلة','مطاعم وأطباق محفوظة',(){}),st(c,Icons.local_offer_outlined,'العروض والكوبونات','خصومات وعروض يومية',(){}),st(c,Icons.notifications_none,'الإشعارات','الطلب والعروض',()=>showNotifications(c)),st(c,Icons.dark_mode_outlined,'الوضع الليلي','تخصيص المظهر',()=>onDark(!dark),trailing:Switch(value:dark,onChanged:onDark)),st(c,Icons.security,'الأمان والخصوصية','حماية الحساب',(){}),st(c,Icons.help_outline,'مركز المساعدة','دعم وشكاوى ومحادثة',(){}),const SizedBox(height:12),OutlinedButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const Roles())),icon:const Icon(Icons.dashboard_customize_outlined),label:const Text('لوحات المطعم والسائق والإدارة'))]);}
Widget st(BuildContext c,IconData i,String a,String b,VoidCallback f,{Widget? trailing})=>Container(margin:const EdgeInsets.only(bottom:9),decoration:BoxDecoration(color:Theme.of(c).colorScheme.surface,borderRadius:BorderRadius.circular(18)),child:ListTile(onTap:f,leading:Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:orange.withValues(alpha:.1),borderRadius:BorderRadius.circular(13)),child:Icon(i,color:orange)),title:Text(a,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:14)),subtitle:Text(b,style:const TextStyle(color:muted,fontSize:11)),trailing:trailing??const Icon(Icons.chevron_left)));

class MapPage extends StatelessWidget{final R? restaurant;const MapPage({super.key,this.restaurant});@override Widget build(BuildContext c){final center=restaurant==null?const LatLng(31.0445,31.3540):LatLng(restaurant!.lat,restaurant!.lng);final list=restaurant==null?data:[restaurant!];return Scaffold(appBar:AppBar(title:Text(restaurant==null?'خريطة المطاعم':'موقع '+restaurant!.name)),body:FlutterMap(options:MapOptions(initialCenter:center,initialZoom:restaurant==null?14.2:15.2),children:[TileLayer(urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png',userAgentPackageName:'com.nova.delivery'),MarkerLayer(markers:list.map((r)=>Marker(point:LatLng(r.lat,r.lng),width:48,height:48,child:GestureDetector(onTap:()=>showModalBottomSheet(context:c,showDragHandle:true,builder:(_)=>Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(r.name,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:8),Text(r.address,style:const TextStyle(color:muted)),const SizedBox(height:12),FilledButton(onPressed:()=>Navigator.pop(c),child:const Text('اختيار المطعم'))])),child:Container(decoration:BoxDecoration(color:orange,shape:BoxShape.circle,border:Border.all(color:Colors.white,width:3)),child:const Icon(Icons.restaurant,color:Colors.white))))).toList())]));}}

class Roles extends StatelessWidget{const Roles({super.key});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('مركز نوفا')),body:ListView(padding:const EdgeInsets.all(18),children:[const Text('لوحات النظام',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:18),role(c,Icons.restaurant_menu,'لوحة المطعم','الطلبات • المنيو • المخزون • الأرباح'),role(c,Icons.delivery_dining,'لوحة السائق','التكليفات • الملاحة • المحفظة • الأرباح'),role(c,Icons.admin_panel_settings,'لوحة الإدارة','المطاعم • العملاء • السائقين • التقارير') ]));}
Widget role(BuildContext c,IconData i,String a,String b)=>Container(margin:const EdgeInsets.only(bottom:13),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Theme.of(c).colorScheme.surface,borderRadius:BorderRadius.circular(23)),child:Row(children:[CircleAvatar(backgroundColor:orange.withValues(alpha:.1),child:Icon(i,color:orange)),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17)),Text(b,style:const TextStyle(color:muted,fontSize:11))])),const Icon(Icons.chevron_left)]));

void showNotifications(BuildContext c)=>showModalBottomSheet(context:c,showDragHandle:true,builder:(_)=>const Directionality(textDirection:TextDirection.rtl,child:Padding(padding:EdgeInsets.all(18),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text('الإشعارات',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),ListTile(leading:Icon(Icons.delivery_dining,color:orange),title:Text('طلبك NV-2841 في الطريق'),subtitle:Text('السائق استلم الطلب وسيصل قريباً')),ListTile(leading:Icon(Icons.local_offer,color:orange),title:Text('عرض جديد من بازوكا'),subtitle:Text('اكتشف أحدث العروض في المنصورة')),ListTile(leading:Icon(Icons.auto_awesome,color:orange),title:Text('نوفا ترحب بك'),subtitle:Text('مطاعم وفروع وبيانات حقيقية حولك'))])));

void checkout(BuildContext c,double total)=>showModalBottomSheet(context:c,showDragHandle:true,builder:(_)=>Directionality(textDirection:TextDirection.rtl,child:Padding(padding:const EdgeInsets.all(18),child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('تأكيد الطلب',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:14),st(c,Icons.location_on,'عنوان التوصيل','المنصورة • اختر عنواناً',(){}),st(c,Icons.payments,'طريقة الدفع','الدفع عند الاستلام',(){}),line('الإجمالي النهائي',total,bold:true),const SizedBox(height:14),FilledButton(onPressed:(){Navigator.pop(c);ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('تم إرسال الطلب بنجاح 🎉')));},style:FilledButton.styleFrom(backgroundColor:orange,minimumSize:const Size.fromHeight(54)),child:const Text('تأكيد وإرسال الطلب'))])));
