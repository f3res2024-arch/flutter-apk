import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_service.dart';

const ownerOrange=Color(0xFFFF5A36);
const ownerInk=Color(0xFF151922);
const ownerMuted=Color(0xFF747A86);

class NovaOwnerControlCenter extends StatefulWidget{
  const NovaOwnerControlCenter({super.key});
  @override State<NovaOwnerControlCenter> createState()=>_NovaOwnerControlCenterState();
}
class _NovaOwnerControlCenterState extends State<NovaOwnerControlCenter>{
  int tab=0;bool loading=true; RealtimeChannel? supportChannel;
  List<Map<String,dynamic>> restaurants=[],orders=[],coupons=[],offers=[],content=[],support=[];
  static const labels=['الرئيسية','الطلبات','المطاعم','المنتجات','العروض','واجهة التطبيق','الدعم','الإعدادات'];
  static const icons=[Icons.space_dashboard,Icons.receipt_long,Icons.storefront,Icons.restaurant_menu,Icons.local_offer,Icons.auto_awesome,Icons.support_agent,Icons.tune];
  String s(Map<String,dynamic> m,String k)=>m[k]?.toString()??'';
  String id(dynamic x){final a=x?.toString()??'';return a.length>7?a.substring(0,7):a;}
  double n(dynamic x)=>double.tryParse(x?.toString()??'0')??0;
  int get active=>orders.where((x)=>!['delivered','cancelled'].contains(x['status'])).length;
  int get waitingSupport=>support.where((x)=>x['status']=='waiting_admin').length;
  int get delivered=>orders.where((x)=>x['status']=='delivered').length;
  double get revenue=>orders.fold(0,(a,x)=>a+n(x['total']));
  @override void initState(){super.initState();refresh();supportChannel=NovaSupabase.watchSupportInbox(refresh);}
  @override void dispose(){supportChannel?.unsubscribe();super.dispose();}
  Future<void> refresh()async{
    if(mounted)setState(()=>loading=true);
    try{
      final r=await Future.wait([NovaSupabase.restaurants(),NovaSupabase.ownerOrders(),NovaSupabase.ownerCoupons(),NovaSupabase.ownerOffers(),NovaSupabase.appContent(),NovaSupabase.ownerSupportConversations()]);
      if(!mounted)return;
      setState((){
        restaurants=List<Map<String,dynamic>>.from(r[0] as List);orders=List<Map<String,dynamic>>.from(r[1] as List);
        coupons=List<Map<String,dynamic>>.from(r[2] as List);offers=List<Map<String,dynamic>>.from(r[3] as List);
        content=List<Map<String,dynamic>>.from(r[4] as List);support=List<Map<String,dynamic>>.from(r[5] as List);
      });
    }catch(e){if(mounted)_msg('تعذر تحميل البيانات: '+e.toString());}
    finally{if(mounted)setState(()=>loading=false);}
  }
  void _msg(String x){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(x),behavior:SnackBarBehavior.floating));}
  Future<void> form(String title,List<Widget> fields,Future<void> Function() save)async{
    bool busy=false;
    await showModalBottomSheet(context:context,isScrollControlled:true,showDragHandle:true,backgroundColor:Colors.transparent,builder:(d)=>StatefulBuilder(builder:(d,setD)=>Directionality(textDirection:TextDirection.rtl,child:SafeArea(child:Container(
      margin:const EdgeInsets.only(top:28),decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(34))),
      padding:const EdgeInsets.fromLTRB(18,10,18,18),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        Row(children:[Container(width:46,height:46,decoration:BoxDecoration(color:ownerOrange.withValues(alpha:.1),borderRadius:BorderRadius.circular(15)),child:const Icon(Icons.auto_awesome_rounded,color:ownerOrange)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900,color:ownerInk)),const SizedBox(height:3),const Text('عدّل البيانات واحفظ التغييرات مباشرة في مركز نوفا.',style:TextStyle(color:ownerMuted,fontSize:11))])),IconButton(onPressed:busy?null:()=>Navigator.pop(d),icon:const Icon(Icons.close_rounded))]),
        const SizedBox(height:12),
        Flexible(child:SingleChildScrollView(padding:const EdgeInsets.only(bottom:8),child:Column(children:fields))),
        const SizedBox(height:10),
        Row(children:[Expanded(child:OutlinedButton(onPressed:busy?null:()=>Navigator.pop(d),child:const Text('إلغاء'))),const SizedBox(width:10),Expanded(child:FilledButton.icon(onPressed:busy?null:()async{setD(()=>busy=true);try{await save();if(d.mounted)Navigator.pop(d);}catch(e){if(d.mounted)_msg('تعذر الحفظ: '+e.toString());}if(d.mounted)setD(()=>busy=false);},icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(Icons.check_rounded),label:const Text('حفظ التغييرات')))]),
      ]),
    )))));
  }
  Widget imageChooser({String? existingUrl,required void Function(Uint8List bytes,String name) onPicked}) {
    Uint8List? local; String name='';
    return StatefulBuilder(builder:(d,setD)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      if(local!=null)ClipRRect(borderRadius:BorderRadius.circular(20),child:Image.memory(local!,height:150,width:double.infinity,fit:BoxFit.cover))
      else if(existingUrl!=null&&existingUrl.isNotEmpty)ClipRRect(borderRadius:BorderRadius.circular(20),child:Image.network(existingUrl,height:150,width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(height:150,color:const Color(0xFFF1F2F4),child:const Icon(Icons.image_not_supported_rounded,size:42,color:ownerMuted))))
      else Container(height:120,decoration:BoxDecoration(color:const Color(0xFFF7F7F8),borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFFE5E7EB))),child:const Icon(Icons.add_photo_alternate_rounded,size:42,color:ownerOrange)),
      const SizedBox(height:8),OutlinedButton.icon(onPressed:()async{final x=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:92,maxWidth:2200);if(x==null)return;final bytes=await x.readAsBytes();if(d.mounted)setD(()=>local=bytes);onPicked(bytes,x.name);},icon:const Icon(Icons.photo_library_outlined),label:Text(name.isEmpty?'اختيار / تغيير الصورة':'تغيير الصورة • '+name)),
      const SizedBox(height:8),
    ]));
  }
  TextField field(TextEditingController c,String l,{int lines=1,TextInputType? type})=>TextField(controller:c,maxLines:lines,keyboardType:type,decoration:InputDecoration(labelText:l));
  Future<void> addRestaurant()async{
    final a=TextEditingController(),b=TextEditingController(),p=TextEditingController(),f=TextEditingController(text:'0');Uint8List? coverBytes,logoBytes;
    await form('إضافة مطعم جديد',[
      _section('بيانات المطعم',Icons.storefront_rounded),field(a,'اسم المطعم'),field(b,'وصف قصير للواجهة',lines:3),field(p,'الهاتف',type:TextInputType.phone),field(f,'رسوم التوصيل',type:TextInputType.number),
      const SizedBox(height:8),_section('صور المطعم',Icons.photo_library_rounded),imageChooser(onPicked:(bytes,_)=>coverBytes=bytes),imageChooser(onPicked:(bytes,_)=>logoBytes=bytes),
    ],()async{
      final name=a.text.trim();if(name.isEmpty)throw Exception('اكتب اسم المطعم أولاً.');
      final id=await NovaSupabase.createRestaurant(name:name,description:b.text,phone:p.text,deliveryFee:n(f.text));
      if(coverBytes!=null){final url=await NovaSupabase.uploadRestaurantCover(id,coverBytes!);if(url!=null)await NovaSupabase.updateRestaurant(id,coverUrl:url);}
      if(logoBytes!=null){final url=await NovaSupabase.uploadRestaurantImage(id,logoBytes!);if(url!=null)await NovaSupabase.updateRestaurant(id,logoUrl:url);}
      await refresh();
    });a.dispose();b.dispose();p.dispose();f.dispose();
  }
  Future<void> editRestaurant(Map<String,dynamic> r)async{
    final a=TextEditingController(text:s(r,'name')),b=TextEditingController(text:s(r,'description')),p=TextEditingController(text:s(r,'phone'));Uint8List? coverBytes,logoBytes;
    await form('تعديل المطعم',[
      _section('المعلومات الأساسية',Icons.edit_note_rounded),field(a,'الاسم'),field(b,'الوصف',lines:3),field(p,'الهاتف',type:TextInputType.phone),
      const SizedBox(height:8),_section('صور المطعم',Icons.photo_library_rounded),imageChooser(existingUrl:s(r,'cover_url'),onPicked:(bytes,_)=>coverBytes=bytes),imageChooser(existingUrl:s(r,'logo_url'),onPicked:(bytes,_)=>logoBytes=bytes),
    ],()async{
      await NovaSupabase.updateRestaurant(s(r,'id'),name:a.text,description:b.text,phone:p.text);
      if(coverBytes!=null){final url=await NovaSupabase.uploadRestaurantCover(s(r,'id'),coverBytes!);if(url!=null)await NovaSupabase.updateRestaurant(s(r,'id'),coverUrl:url);}
      if(logoBytes!=null){final url=await NovaSupabase.uploadRestaurantImage(s(r,'id'),logoBytes!);if(url!=null)await NovaSupabase.updateRestaurant(s(r,'id'),logoUrl:url);}
      await refresh();
    });a.dispose();b.dispose();p.dispose();
  }
  Future<void> addBranch(Map<String,dynamic> r)async{
    final a=TextEditingController(),b=TextEditingController(),p=TextEditingController();
    await form('إضافة فرع',[field(a,'اسم الفرع'),field(b,'العنوان',lines:2),field(p,'الهاتف')],()async{await NovaSupabase.createBranch(s(r,'id'),name:a.text,address:b.text,phone:p.text);await refresh();});
    a.dispose();b.dispose();p.dispose();
  }
  Future<void> addProduct(Map<String,dynamic> r)async{
    final a=TextEditingController(),b=TextEditingController(),p=TextEditingController();Uint8List? imageBytes;
    await form('إضافة منتج للمنيو',[
      _section('تفاصيل المنتج',Icons.restaurant_menu_rounded),field(a,'اسم المنتج'),field(b,'الوصف',lines:2),field(p,'السعر',type:TextInputType.number),
      const SizedBox(height:8),_section('صورة المنتج',Icons.image_rounded),imageChooser(onPicked:(bytes,_)=>imageBytes=bytes),
    ],()async{
      final price=n(p.text);if(a.text.trim().isEmpty||price<=0)throw Exception('اكتب اسم المنتج والسعر.');
      final id=await NovaSupabase.addMenuItemFull(s(r,'id'),name:a.text,description:b.text,price:price);
      if(imageBytes!=null){final url=await NovaSupabase.uploadMenuImage(id,imageBytes!);if(url!=null)await NovaSupabase.updateMenuItem(id,imageUrl:url);}
      await refresh();
    });a.dispose();b.dispose();p.dispose();
  }
  Future<void> menu(Map<String,dynamic> r)async{
    final m=await NovaSupabase.allRestaurantMenu(s(r,'id'));if(!mounted)return;
    await Navigator.push(context,MaterialPageRoute(builder:(_)=>NovaMenuManager(restaurant:r,items:m,onRefresh:refresh)));
  }
  Future<void> coupon()async{
    final a=TextEditingController(),b=TextEditingController(),p=TextEditingController();
    await form('إنشاء كوبون',[field(a,'الكود'),field(b,'العنوان'),field(p,'نسبة الخصم %',type:TextInputType.number)],()async{await NovaSupabase.createCoupon(code:a.text,title:b.text,discountType:'percent',discountValue:n(p.text));await refresh();});
    a.dispose();b.dispose();p.dispose();
  }
  Future<void> offer()async{
    final a=TextEditingController(),b=TextEditingController();
    Uint8List? imageBytes;
    String? imageName;
    await form('إنشاء عرض',[field(a,'عنوان العرض'),field(b,'الوصف',lines:3),
      StatefulBuilder(builder:(d,setD)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        if(imageBytes!=null)Container(height:130,margin:const EdgeInsets.only(top:12,bottom:8),clipBehavior:Clip.antiAlias,decoration:BoxDecoration(borderRadius:BorderRadius.circular(16)),child:Image.memory(imageBytes!,fit:BoxFit.cover)),
        OutlinedButton.icon(
          onPressed:()async{
            final x=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:88,maxWidth:1800);
            if(x==null)return;
            final bytes=await x.readAsBytes();
            if(d.mounted)setD(() { imageBytes=bytes; imageName=x.name; });
          },
          icon:const Icon(Icons.image_outlined),
          label:Text(imageName==null?'إضافة صورة للعرض':'تغيير الصورة'),
        ),
      ])),
    ],()async{
      final id=await NovaSupabase.createOffer(title:a.text,subtitle:b.text,targetType:'home');
      if(imageBytes!=null){
        final url=await NovaSupabase.uploadOfferImage(id,imageBytes!);
        if(url!=null)await NovaSupabase.updateOffer(id,{'image_url':url});
      }
      await refresh();
    });
    a.dispose();b.dispose();
  }
  Future<void> contentEdit(Map<String,dynamic> x)async{
    final a=TextEditingController(text:s(x,'text_value'));
    Uint8List? imageBytes;
    String? imageName;
    await form('تعديل محتوى '+s(x,'key'),[
      field(a,'النص',lines:5),
      StatefulBuilder(builder:(d,setD)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        if(s(x,'image_url').isNotEmpty)Container(height:130,margin:const EdgeInsets.only(top:12,bottom:8),clipBehavior:Clip.antiAlias,decoration:BoxDecoration(borderRadius:BorderRadius.circular(16)),child:Image.network(s(x,'image_url'),fit:BoxFit.cover)),
        if(imageBytes!=null)Container(height:130,margin:const EdgeInsets.only(top:12,bottom:8),clipBehavior:Clip.antiAlias,decoration:BoxDecoration(borderRadius:BorderRadius.circular(16)),child:Image.memory(imageBytes!,fit:BoxFit.cover)),
        OutlinedButton.icon(
          onPressed:()async{
            final p=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:88,maxWidth:1800);
            if(p==null)return;
            final bytes=await p.readAsBytes();
            if(d.mounted)setD(() { imageBytes=bytes; imageName=p.name; });
          },
          icon:const Icon(Icons.image_outlined),
          label:Text(imageName==null?'تغيير/إضافة صورة':'تغيير الصورة'),
        ),
      ])),
    ],()async{
      await NovaSupabase.updateAppContent(s(x,'key'),a.text);
      if(imageBytes!=null){
        final url=await NovaSupabase.uploadContentImage(s(x,'key'),imageBytes!);
        if(url!=null)await NovaSupabase.updateAppContentImage(s(x,'key'),url);
      }
      await refresh();
    });a.dispose();
  }
  Widget metric(String a,String b,IconData i,Color c)=>Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFE5E7EB)),boxShadow:const[BoxShadow(color:Color(0x08000000),blurRadius:16,offset:Offset(0,6))]),child:Row(children:[Container(width:44,height:44,decoration:BoxDecoration(color:c.withValues(alpha:.1),borderRadius:BorderRadius.circular(14)),child:Icon(i,color:c)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(color:ownerMuted,fontSize:10)),const SizedBox(height:2),Text(b,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900))]))]));
  Widget _section(String title,IconData icon)=>Container(margin:const EdgeInsets.only(top:4,bottom:10),padding:const EdgeInsets.symmetric(horizontal:12,vertical:10),decoration:BoxDecoration(color:const Color(0xFFFFF4F0),borderRadius:BorderRadius.circular(15)),child:Row(children:[Icon(icon,color:ownerOrange,size:20),const SizedBox(width:8),Text(title,style:const TextStyle(color:ownerInk,fontWeight:FontWeight.w900,fontSize:12))]));
  Widget pageTitle(String a,String b)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(b,style:const TextStyle(color:ownerMuted,fontSize:12))]);
  Widget card(Widget child)=>Container(padding:const EdgeInsets.all(15),margin:const EdgeInsets.only(bottom:10),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFE5E7EB))),child:child);
  Widget overview()=>ListView(children:[
    Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(gradient:const LinearGradient(colors:[ownerInk,Color(0xFF303746)]),borderRadius:BorderRadius.circular(30)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('NOVA CONTROL CENTER',style:TextStyle(color:Colors.white,fontSize:27,fontWeight:FontWeight.w900)),SizedBox(height:7),Text('إدارة كاملة للتطبيق من مكان واحد: مطاعم، منتجات، طلبات، عروض، محتوى ودعم.',style:TextStyle(color:Colors.white70,fontSize:12,height:1.5))])),
    const SizedBox(height:16),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.55,children:[metric('المبيعات',revenue.toStringAsFixed(0)+' ج.م',Icons.payments,Colors.green),metric('طلبات نشطة',active.toString(),Icons.local_shipping,ownerOrange),metric('تم التسليم',delivered.toString(),Icons.done_all,Colors.indigo),metric('المطاعم',restaurants.length.toString(),Icons.storefront,Colors.blue)]),
    const SizedBox(height:16),card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('تشغيل سريع',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900)),const SizedBox(height:10),Wrap(spacing:8,runSpacing:8,children:[ActionChip(label:const Text('مطعم جديد'),avatar:const Icon(Icons.add_business,color:ownerOrange),onPressed:addRestaurant),ActionChip(label:const Text('منتج جديد'),avatar:const Icon(Icons.add_circle,color:ownerOrange),onPressed:restaurants.isEmpty?null:()=>addProduct(restaurants.first)),ActionChip(label:const Text('كوبون'),avatar:const Icon(Icons.confirmation_number,color:ownerOrange),onPressed:coupon),ActionChip(label:const Text('عرض'),avatar:const Icon(Icons.campaign,color:ownerOrange),onPressed:offer),ActionChip(label:const Text('واجهة التطبيق'),avatar:const Icon(Icons.auto_awesome,color:ownerOrange),onPressed:()=>setState(()=>tab=5))])]))
  ]);
  Widget ordersPage()=>ListView(children:[pageTitle('إدارة الطلبات','متابعة وتغيير حالات الطلبات.'),const SizedBox(height:14),Row(children:[Expanded(child:metric('كل الطلبات',orders.length.toString(),Icons.receipt_long,ownerOrange)),const SizedBox(width:8),Expanded(child:metric('نشطة',active.toString(),Icons.bolt,Colors.green))]),const SizedBox(height:12),...orders.map((o)=>card(ListTile(title:Text(s(o,'restaurant_name'),style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('#'+id(o['id'])+' • '+s(o,'customer_name')),leading:const Icon(Icons.receipt_long,color:ownerOrange),trailing:PopupMenuButton<String>(onSelected:(x)async{await NovaSupabase.ownerUpdateOrderStatus(s(o,'id'),x);await refresh();},itemBuilder:(_)=>const['pending','accepted','preparing','ready','picked_up','on_the_way','delivered','cancelled'].map((x)=>PopupMenuItem(value:x,child:Text(x))).toList(),child:Chip(label:Text(s(o,'status')))))) )]);
  Widget restaurantsPage()=>ListView(children:[
    pageTitle('المطاعم والفروع','إدارة الصور، البيانات، الفروع والمنيو من مكان واحد.'),
    const SizedBox(height:14),
    Container(
      padding:const EdgeInsets.all(18),
      decoration:BoxDecoration(gradient:const LinearGradient(colors:[ownerInk,Color(0xFF303746)]),borderRadius:BorderRadius.circular(26)),
      child:Row(children:[
        Container(width:54,height:54,decoration:BoxDecoration(color:ownerOrange,borderRadius:BorderRadius.circular(18)),child:const Icon(Icons.storefront_rounded,color:Colors.white,size:28)),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('استوديو المطاعم',style:TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.w900)),
          Text(restaurants.length.toString()+' مطعم نشط • الصور والمنيو قابلة للتعديل فوراً',style:const TextStyle(color:Colors.white70,fontSize:11)),
        ])),
        IconButton(onPressed:addRestaurant,style:IconButton.styleFrom(backgroundColor:ownerOrange,foregroundColor:Colors.white),icon:const Icon(Icons.add_rounded)),
      ]),
    ),
    const SizedBox(height:14),
    ...restaurants.map((r)=>card(Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Stack(children:[
        ClipRRect(borderRadius:BorderRadius.circular(20),child:Image.network((r['cover_url']??r['logo_url']??'').toString(),width:double.infinity,height:150,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(height:150,color:const Color(0xFFF1F2F4),child:const Icon(Icons.storefront_rounded,size:55,color:ownerOrange)))),
        Positioned(right:12,top:12,child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.95),borderRadius:BorderRadius.circular(14)),child:const Row(children:[Icon(Icons.circle,size:9,color:Colors.green),SizedBox(width:6),Text('نشط',style:TextStyle(fontSize:10,fontWeight:FontWeight.w900))]))),
      ]),
      const SizedBox(height:12),
      Row(children:[
        Container(width:54,height:54,decoration:BoxDecoration(color:const Color(0xFFFFF3EF),borderRadius:BorderRadius.circular(17),border:Border.all(color:const Color(0xFFFFDDD3))),child:ClipRRect(borderRadius:BorderRadius.circular(16),child:Image.network((r['logo_url']??r['cover_url']??'').toString(),fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.restaurant_rounded,color:ownerOrange)))),
        const SizedBox(width:11),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(s(r,'name'),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17)),
          const SizedBox(height:3),
          Text(s(r,'description'),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:ownerMuted,fontSize:10)),
        ])),
        PopupMenuButton<String>(
          onSelected:(x)async{
            if(x=='edit')await editRestaurant(r);
            if(x=='branch')await addBranch(r);
            if(x=='menu')await menu(r);
            if(x=='delete'){
              final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(
                title:const Text('إيقاف المطعم؟'),
                content:Text('سيختفي '+s(r,'name')+' من التطبيق للعملاء.'),
                actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('إيقاف'))],
              ));
              if(ok==true){await NovaSupabase.deleteRestaurant(s(r,'id'));await refresh();}
            }
          },
          itemBuilder:(_)=>const[
            PopupMenuItem(value:'edit',child:Text('تعديل البيانات والصور')),
            PopupMenuItem(value:'branch',child:Text('إضافة فرع')),
            PopupMenuItem(value:'menu',child:Text('إدارة المنيو')),
            PopupMenuItem(value:'delete',child:Text('إيقاف المطعم')),
          ],
        ),
      ]),
      const SizedBox(height:12),
      Row(children:[
        Expanded(child:OutlinedButton.icon(onPressed:()=>addBranch(r),icon:const Icon(Icons.location_on_outlined),label:const Text('إضافة فرع'))),
        const SizedBox(width:8),
        Expanded(child:FilledButton.icon(onPressed:()=>menu(r),icon:const Icon(Icons.restaurant_menu_rounded),label:const Text('إدارة المنيو'))),
      ]),
    ]))),
  ]);
  Widget menuPage()=>ListView(children:[pageTitle('المنتجات والمنيو','إدارة الأسعار والتوفر والمنتجات لكل مطعم.'),const SizedBox(height:12),...restaurants.map((r)=>card(ListTile(title:Text(s(r,'name'),style:const TextStyle(fontWeight:FontWeight.w900)),leading:const Icon(Icons.restaurant_menu,color:ownerOrange),trailing:const Icon(Icons.chevron_left),onTap:()=>menu(r))))]);
  Widget marketingPage()=>ListView(children:[pageTitle('العروض والكوبونات','إنشاء وتفعيل وإيقاف الحملات.'),const SizedBox(height:12),Row(children:[Expanded(child:FilledButton.icon(onPressed:coupon,icon:const Icon(Icons.confirmation_number),label:const Text('كوبون'))),const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:offer,icon:const Icon(Icons.campaign),label:const Text('عرض')))]),const SizedBox(height:12),card(Column(children:coupons.map((x)=>SwitchListTile(contentPadding:EdgeInsets.zero,title:Text(s(x,'code')+' • '+s(x,'title')),subtitle:Text(s(x,'discount_value')+'% خصم'),value:x['is_active']==true,onChanged:(b)async{await NovaSupabase.updateCoupon(s(x,'id'),{'is_active':b});await refresh();})).toList())),card(Column(children:offers.map((x)=>SwitchListTile(contentPadding:EdgeInsets.zero,title:Text(s(x,'title')),subtitle:Text(s(x,'subtitle')),value:x['is_active']==true,onChanged:(b)async{await NovaSupabase.updateOffer(s(x,'id'),{'is_active':b});await refresh();})).toList()))]);
  Widget contentPage()=>ListView(children:[pageTitle('واجهة التطبيق','تعديل النصوص والصور بدون تحديث APK.'),const SizedBox(height:12),card(Column(children:content.map((x)=>ListTile(contentPadding:EdgeInsets.zero,title:Text(s(x,'key'),style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(s(x,'text_value'),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:ownerMuted,fontSize:10)),trailing:IconButton(onPressed:()=>contentEdit(x),icon:const Icon(Icons.edit,color:ownerOrange)))).toList()))]);
  Widget supportPage()=>ListView(children:[
    pageTitle('الدعم الفني','طلبات العملاء التي تحتاج قبول المسؤول أو متابعة محادثة قائمة.'),
    const SizedBox(height:12),
    if(waitingSupport>0)
      Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:ownerOrange.withValues(alpha:.08),borderRadius:BorderRadius.circular(22),border:Border.all(color:ownerOrange.withValues(alpha:.18))),child:Row(children:[
        const CircleAvatar(backgroundColor:ownerOrange,child:Icon(Icons.notifications_active_rounded,color:Colors.white)),const SizedBox(width:12),
        Expanded(child:Text('في انتظارك '+waitingSupport.toString()+' عميل للدعم الفني.',style:const TextStyle(fontWeight:FontWeight.w900))),
        Text(waitingSupport.toString(),style:const TextStyle(color:ownerOrange,fontSize:24,fontWeight:FontWeight.w900)),
      ])),
    const SizedBox(height:12),
    ...support.map((x)=>card(ListTile(
      title:Text('عميل مجهول #'+id(x['id']),style:const TextStyle(fontWeight:FontWeight.w900)),
      subtitle:Text(x['status']=='waiting_admin'?'في انتظار القبول':x['status']=='admin_active'?'محادثة مفتوحة':'محادثة مع Nova AI'),
      leading:Stack(clipBehavior:Clip.none,children:[const CircleAvatar(backgroundColor:Color(0x12FF5A36),child:Icon(Icons.support_agent,color:ownerOrange)),if(x['status']=='waiting_admin')const Positioned(right:-2,top:-2,child:CircleAvatar(radius:7,backgroundColor:ownerOrange))]),
      trailing:x['status']=='waiting_admin'
        ?Wrap(spacing:6,children:[
            IconButton(tooltip:'قبول',onPressed:()async{try{final ok=await NovaSupabase.claimSupportConversation(s(x,'id'));if(!ok){_msg('تم استلام المحادثة بواسطة مسؤول آخر.');return;}await refresh();if(mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>NovaOwnerChat(conversationId:s(x,'id'))));}catch(e){_msg('تعذر قبول المحادثة: '+e.toString());}},style:IconButton.styleFrom(backgroundColor:ownerOrange,foregroundColor:Colors.white),icon:const Icon(Icons.check_rounded)),
            IconButton(tooltip:'رفض',onPressed:()async{try{await NovaSupabase.rejectSupportConversation(s(x,'id'));await refresh();}catch(e){_msg('تعذر رفض المحادثة: '+e.toString());}},icon:const Icon(Icons.close_rounded,color:Colors.redAccent)),
          ])
        :const Icon(Icons.chevron_left_rounded),
      onTap:x['status']=='waiting_admin'?null:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>NovaOwnerChat(conversationId:s(x,'id')))),
    ))),
  ]);
  Widget settingsPage()=>ListView(children:[pageTitle('الإعدادات','حالة النظام وصلاحيات حساب المالك.'),const SizedBox(height:12),card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(NovaSupabase.currentUser?.email??'حساب المالك',style:const TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:5),const Text('RLS يحمي عمليات الإدارة الحساسة.',style:TextStyle(color:ownerMuted,fontSize:11)),const SizedBox(height:12),OutlinedButton.icon(onPressed:()=>NovaSupabase.signOut(),icon:const Icon(Icons.logout),label:const Text('تسجيل الخروج'))]))]);
  @override
  Widget build(BuildContext c){
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator(color:ownerOrange)));
    final pages=[overview(),ordersPage(),restaurantsPage(),menuPage(),marketingPage(),contentPage(),supportPage(),settingsPage()];
    return Directionality(
      textDirection:TextDirection.rtl,
      child:LayoutBuilder(builder:(c,box){
        final wide=box.maxWidth>=900;
        return Scaffold(
          backgroundColor:const Color(0xFFF7F8FA),
          appBar:AppBar(
            backgroundColor:Colors.white,
            title:const Text('مركز تحكم نوفا',style:TextStyle(fontWeight:FontWeight.w900)),
            actions:[
              IconButton(onPressed:()=>setState(()=>tab=6),tooltip:'الدعم الفني',icon:Badge(isLabelVisible:waitingSupport>0,label:Text(waitingSupport.toString()),backgroundColor:ownerOrange,child:const Icon(Icons.support_agent_rounded))),
              IconButton(onPressed:refresh,icon:const Icon(Icons.refresh)),
              IconButton(onPressed:()=>NovaSupabase.signOut(),icon:const Icon(Icons.logout)),
            ],
          ),
          body:Row(children:[
            if(wide)
              Container(
                width:245,margin:const EdgeInsets.fromLTRB(14,14,0,14),padding:const EdgeInsets.all(10),
                decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(26),border:Border.all(color:const Color(0xFFE5E7EB))),
                child:ListView(children:[
                  const Padding(padding:EdgeInsets.all(14),child:Text('NOVA ADMIN',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900))),
                  ...List.generate(labels.length,(i)=>ListTile(
                    selected:tab==i,
                    selectedTileColor:ownerOrange.withValues(alpha:.1),
                    leading:Icon(icons[i],color:tab==i?ownerOrange:ownerMuted),
                    title:Text(labels[i],style:TextStyle(fontSize:12,fontWeight:tab==i?FontWeight.w900:FontWeight.w700)),
                    onTap:()=>setState(()=>tab=i),
                  )),
                ]),
              ),
            Expanded(child:Padding(padding:const EdgeInsets.fromLTRB(18,18,18,22),child:pages[tab])),
          ]),
          bottomNavigationBar:wide?null:NavigationBar(
            selectedIndex:tab>4?4:tab,
            onDestinationSelected:(i)=>setState(()=>tab=i),
            destinations:const[
              NavigationDestination(icon:Icon(Icons.space_dashboard),label:'الرئيسية'),
              NavigationDestination(icon:Icon(Icons.receipt_long),label:'الطلبات'),
              NavigationDestination(icon:Icon(Icons.storefront),label:'المطاعم'),
              NavigationDestination(icon:Icon(Icons.restaurant_menu),label:'المنيو'),
              NavigationDestination(icon:Icon(Icons.local_offer),label:'العروض'),
            ],
          ),
        );
      }),
    );
  }
}

class NovaMenuManager extends StatefulWidget{
  final Map<String,dynamic> restaurant;
  final List<Map<String,dynamic>> items;
  final Future<void> Function() onRefresh;
  const NovaMenuManager({super.key,required this.restaurant,required this.items,required this.onRefresh});
  @override State<NovaMenuManager> createState()=>_NovaMenuManagerState();
}
class _NovaMenuManagerState extends State<NovaMenuManager>{
  late List<Map<String,dynamic>> items;
  @override void initState(){super.initState();items=[...widget.items];}
  Future<void> reload()async{
    final x=await NovaSupabase.allRestaurantMenu(widget.restaurant['id'].toString());
    if(mounted)setState(()=>items=x);
  }
  Future<void> add()async{
    final n=TextEditingController(),p=TextEditingController(),d=TextEditingController();
    Uint8List? imageBytes;
    await showModalBottomSheet(
      context:context,isScrollControlled:true,showDragHandle:true,backgroundColor:Colors.transparent,
      builder:(sheet)=>StatefulBuilder(builder:(sheet,setSheet)=>Directionality(
        textDirection:TextDirection.rtl,
        child:SafeArea(child:Container(
          margin:const EdgeInsets.only(top:28),
          padding:EdgeInsets.fromLTRB(18,10,18,18+MediaQuery.viewInsetsOf(sheet).bottom),
          decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(34))),
          child:Column(mainAxisSize:MainAxisSize.min,children:[
            Row(children:[
              Container(width:48,height:48,decoration:BoxDecoration(color:ownerOrange.withValues(alpha:.1),borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.add_a_photo_rounded,color:ownerOrange)),
              const SizedBox(width:12),
              const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text('إضافة منتج للمنيو',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900)),
                Text('أضف صورة ووصف وسعر وتوفر المنتج.',style:TextStyle(color:ownerMuted,fontSize:11)),
              ])),
            ]),
            const SizedBox(height:14),
            ConstrainedBox(
              constraints:BoxConstraints(maxHeight:MediaQuery.sizeOf(sheet).height*.58),
              child:SingleChildScrollView(child:Column(children:[
                TextField(controller:n,decoration:const InputDecoration(labelText:'اسم المنتج')),
                const SizedBox(height:10),
                TextField(controller:d,maxLines:3,decoration:const InputDecoration(labelText:'الوصف')),
                const SizedBox(height:10),
                TextField(controller:p,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'السعر بالجنيه')),
                const SizedBox(height:12),
                if(imageBytes!=null)
                  ClipRRect(borderRadius:BorderRadius.circular(20),child:Image.memory(imageBytes!,height:160,width:double.infinity,fit:BoxFit.cover))
                else
                  Container(height:130,width:double.infinity,decoration:BoxDecoration(color:const Color(0xFFF7F7F8),borderRadius:BorderRadius.circular(20)),child:const Icon(Icons.add_photo_alternate_rounded,size:45,color:ownerOrange)),
                const SizedBox(height:8),
                OutlinedButton.icon(
                  onPressed:()async{
                    final pick=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:92,maxWidth:2200);
                    if(pick==null)return;
                    final bytes=await pick.readAsBytes();
                    if(sheet.mounted)setSheet(()=>imageBytes=bytes);
                  },
                  icon:const Icon(Icons.photo_library_outlined),
                  label:const Text('اختيار صورة المنتج'),
                ),
              ])),
            ),
            const SizedBox(height:10),
            Row(children:[
              Expanded(child:OutlinedButton(onPressed:()=>Navigator.pop(sheet),child:const Text('إلغاء'))),
              const SizedBox(width:10),
              Expanded(child:FilledButton.icon(
                onPressed:()async{
                  try{
                    final price=double.tryParse(p.text)??0;
                    if(n.text.trim().isEmpty||price<=0)throw Exception('اكتب اسم المنتج والسعر.');
                    final id=await NovaSupabase.addMenuItemFull(widget.restaurant['id'].toString(),name:n.text,description:d.text,price:price);
                    if(imageBytes!=null){
                      final url=await NovaSupabase.uploadMenuImage(id,imageBytes!);
                      if(url!=null)await NovaSupabase.updateMenuItem(id,imageUrl:url);
                    }
                    if(sheet.mounted)Navigator.pop(sheet);
                    await reload();await widget.onRefresh();
                  }catch(e){
                    if(sheet.mounted)ScaffoldMessenger.of(sheet).showSnackBar(SnackBar(content:Text('تعذر الحفظ: '+e.toString())));
                  }
                },
                icon:const Icon(Icons.check_rounded),label:const Text('إضافة المنتج'),
              )),
            ]),
          ]),
        )),
      )),
    );
    n.dispose();p.dispose();d.dispose();
  }
  Future<void> edit(Map<String,dynamic> x)async{
    final n=TextEditingController(text:(x['name']??'').toString());
    final p=TextEditingController(text:(x['price']??0).toString());
    final d=TextEditingController(text:(x['description']??'').toString());
    Uint8List? imageBytes;
    await showModalBottomSheet(
      context:context,isScrollControlled:true,showDragHandle:true,backgroundColor:Colors.transparent,
      builder:(sheet)=>StatefulBuilder(builder:(sheet,setSheet)=>Directionality(textDirection:TextDirection.rtl,child:SafeArea(child:Container(
        margin:const EdgeInsets.only(top:28),padding:EdgeInsets.fromLTRB(18,10,18,18+MediaQuery.viewInsetsOf(sheet).bottom),
        decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(34))),
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          Row(children:[const Icon(Icons.edit_rounded,color:ownerOrange,size:30),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('تعديل المنتج',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900)),
            Text((x['name']??'').toString(),style:const TextStyle(color:ownerMuted,fontSize:11)),
          ]))]),
          const SizedBox(height:14),
          ConstrainedBox(constraints:BoxConstraints(maxHeight:MediaQuery.sizeOf(sheet).height*.58),child:SingleChildScrollView(child:Column(children:[
            TextField(controller:n,decoration:const InputDecoration(labelText:'اسم المنتج')),
            const SizedBox(height:10),TextField(controller:d,maxLines:3,decoration:const InputDecoration(labelText:'الوصف')),
            const SizedBox(height:10),TextField(controller:p,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'السعر')),
            const SizedBox(height:12),
            if(imageBytes!=null)
              ClipRRect(borderRadius:BorderRadius.circular(20),child:Image.memory(imageBytes!,height:160,width:double.infinity,fit:BoxFit.cover))
            else if((x['image_url']??'').toString().isNotEmpty)
              ClipRRect(borderRadius:BorderRadius.circular(20),child:Image.network(x['image_url'].toString(),height:160,width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(height:160,color:const Color(0xFFF1F2F4),child:const Icon(Icons.image_not_supported_rounded,size:40,color:ownerMuted))))
            else
              Container(height:130,width:double.infinity,decoration:BoxDecoration(color:const Color(0xFFF7F7F8),borderRadius:BorderRadius.circular(20)),child:const Icon(Icons.image_rounded,size:45,color:ownerOrange)),
            const SizedBox(height:8),
            OutlinedButton.icon(onPressed:()async{
              final pick=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:92,maxWidth:2200);
              if(pick==null)return;
              final bytes=await pick.readAsBytes();
              if(sheet.mounted)setSheet(()=>imageBytes=bytes);
            },icon:const Icon(Icons.photo_library_outlined),label:const Text('تغيير صورة المنتج')),
          ]))),
          const SizedBox(height:10),
          Row(children:[
            Expanded(child:OutlinedButton(onPressed:()=>Navigator.pop(sheet),child:const Text('إلغاء'))),
            const SizedBox(width:10),
            Expanded(child:FilledButton.icon(onPressed:()async{
              try{
                final price=double.tryParse(p.text)??0;
                if(n.text.trim().isEmpty||price<=0)throw Exception('اكتب اسم المنتج والسعر.');
                await NovaSupabase.updateMenuItem(x['id'].toString(),name:n.text,description:d.text,price:price);
                if(imageBytes!=null){
                  final url=await NovaSupabase.uploadMenuImage(x['id'].toString(),imageBytes!);
                  if(url!=null)await NovaSupabase.updateMenuItem(x['id'].toString(),imageUrl:url);
                }
                if(sheet.mounted)Navigator.pop(sheet);
                await reload();await widget.onRefresh();
              }catch(e){
                if(sheet.mounted)ScaffoldMessenger.of(sheet).showSnackBar(SnackBar(content:Text('تعذر الحفظ: '+e.toString())));
              }
            },icon:const Icon(Icons.check_rounded),label:const Text('حفظ التعديلات'))),
          ]),
        ]),
      )))),
    );
    n.dispose();p.dispose();d.dispose();
  }
  Future<void> remove(Map<String,dynamic> x)async{
    final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(
      title:const Text('إخفاء المنتج؟'),
      content:Text('سيختفي "'+(x['name']??'المنتج').toString()+'" من منيو العملاء.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('إخفاء'))],
    ));
    if(ok==true){await NovaSupabase.deleteMenuItem(x['id'].toString());await reload();await widget.onRefresh();}
  }
  Widget itemCard(Map<String,dynamic> x){
    final available=x['is_available']==true;
    return Container(margin:const EdgeInsets.only(bottom:12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:const Color(0xFFE5E7EB))),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Stack(children:[
        ClipRRect(borderRadius:const BorderRadius.vertical(top:Radius.circular(24)),child:Image.network((x['image_url']??'').toString(),height:145,width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(height:145,color:const Color(0xFFF4F5F7),child:const Icon(Icons.restaurant_menu_rounded,size:52,color:ownerOrange)))),
        Positioned(right:12,top:12,child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.95),borderRadius:BorderRadius.circular(13)),child:Row(children:[Icon(Icons.circle,size:9,color:available?Colors.green:Colors.redAccent),const SizedBox(width:5),Text(available?'متاح الآن':'مخفي',style:const TextStyle(fontSize:10,fontWeight:FontWeight.w900))]))),
      ]),
      Padding(padding:const EdgeInsets.fromLTRB(14,12,14,14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text((x['name']??'منتج').toString(),style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:4),
        Text((x['description']??'').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:ownerMuted,fontSize:10)),const SizedBox(height:8),
        Row(children:[Text((x['price']??0).toString()+' ج.م',style:const TextStyle(color:ownerOrange,fontSize:17,fontWeight:FontWeight.w900)),const Spacer(),Switch(value:available,onChanged:(b)async{await NovaSupabase.setMenuItemAvailability(x['id'].toString(),b);await reload();await widget.onRefresh();}),IconButton(onPressed:()=>edit(x),tooltip:'تعديل',icon:const Icon(Icons.edit_rounded,color:ownerOrange)),IconButton(onPressed:()=>remove(x),tooltip:'إخفاء',icon:const Icon(Icons.delete_outline_rounded,color:Colors.redAccent))]),
      ])),
    ]));
  }
  @override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    backgroundColor:const Color(0xFFF7F8FA),
    appBar:AppBar(
      title:Text((widget.restaurant['name']??'المنيو').toString(),style:const TextStyle(fontWeight:FontWeight.w900)),
      actions:[IconButton(onPressed:reload,icon:const Icon(Icons.refresh_rounded)),Padding(padding:const EdgeInsets.only(left:8),child:IconButton(onPressed:add,style:IconButton.styleFrom(backgroundColor:ownerOrange,foregroundColor:Colors.white),icon:const Icon(Icons.add_rounded)))],
    ),
    body:items.isEmpty
      ? Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.restaurant_menu_rounded,size:70,color:ownerOrange),const SizedBox(height:10),const Text('المنيو فاضية',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:5),const Text('ابدأ بإضافة أول منتج بالصور والسعر.',style:TextStyle(color:ownerMuted)),const SizedBox(height:16),FilledButton.icon(onPressed:add,icon:const Icon(Icons.add),label:const Text('إضافة أول منتج'))])
      :GridView.builder(
          padding:const EdgeInsets.all(16),
          gridDelegate:const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent:430,mainAxisExtent:330,crossAxisSpacing:12,mainAxisSpacing:12),
          itemCount:items.length,itemBuilder:(_,i)=>itemCard(items[i]),
        ),
  ));
}
class NovaOwnerChat extends StatefulWidget{final String conversationId;const NovaOwnerChat({super.key,required this.conversationId});@override State<NovaOwnerChat> createState()=>_NovaOwnerChatState();}
class _NovaOwnerChatState extends State<NovaOwnerChat>{
  final input=TextEditingController();List<Map<String,dynamic>> messages=[];RealtimeChannel? channel;
  @override void initState(){super.initState();load();channel=NovaSupabase.watchSupportMessages(widget.conversationId,load);}
  @override void dispose(){channel?.unsubscribe();input.dispose();super.dispose();}
  Future<void> load()async{final x=await NovaSupabase.ownerSupportMessages(widget.conversationId);if(mounted)setState(()=>messages=x);}
  Future<void> send()async{final x=input.text.trim();if(x.isEmpty)return;input.clear();await NovaSupabase.ownerReplySupport(widget.conversationId,x);await load();}
  @override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('عميل مجهول • الدعم الفني')),body:Column(children:[Expanded(child:ListView.builder(itemCount:messages.length,itemBuilder:(_,i)=>ListTile(title:Text(messages[i]['sender_type'].toString()),subtitle:Text(messages[i]['body'].toString())))),SafeArea(child:Row(children:[Expanded(child:TextField(controller:input)),IconButton(onPressed:send,icon:const Icon(Icons.send,color:ownerOrange))]))])));
}
