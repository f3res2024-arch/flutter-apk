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
    await showDialog(context:context,builder:(d)=>StatefulBuilder(builder:(d,setD)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(28)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w900)),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:fields)),
      actions:[TextButton(onPressed:busy?null:()=>Navigator.pop(d),child:const Text('إلغاء')),FilledButton(onPressed:busy?null:()async{setD(()=>busy=true);try{await save();if(d.mounted)Navigator.pop(d);}catch(e){if(d.mounted)_msg('تعذر الحفظ: '+e.toString());}if(d.mounted)setD(()=>busy=false);},child:busy?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('حفظ'))],
    ))));
  }
  TextField field(TextEditingController c,String l,{int lines=1,TextInputType? type})=>TextField(controller:c,maxLines:lines,keyboardType:type,decoration:InputDecoration(labelText:l));
  Future<void> addRestaurant()async{
    final a=TextEditingController(),b=TextEditingController(),p=TextEditingController(),f=TextEditingController(text:'0');
    await form('إضافة مطعم',[field(a,'اسم المطعم'),field(b,'الوصف',lines:3),field(p,'الهاتف'),field(f,'رسوم التوصيل',type:TextInputType.number)],()async{await NovaSupabase.createRestaurant(name:a.text,description:b.text,phone:p.text,deliveryFee:n(f.text));await refresh();});
    a.dispose();b.dispose();p.dispose();f.dispose();
  }
  Future<void> editRestaurant(Map<String,dynamic> r)async{
    final a=TextEditingController(text:s(r,'name')),b=TextEditingController(text:s(r,'description')),p=TextEditingController(text:s(r,'phone'));
    await form('تعديل المطعم',[field(a,'الاسم'),field(b,'الوصف',lines:3),field(p,'الهاتف')],()async{await NovaSupabase.updateRestaurant(s(r,'id'),name:a.text,description:b.text,phone:p.text);await refresh();});
    a.dispose();b.dispose();p.dispose();
  }
  Future<void> addBranch(Map<String,dynamic> r)async{
    final a=TextEditingController(),b=TextEditingController(),p=TextEditingController();
    await form('إضافة فرع',[field(a,'اسم الفرع'),field(b,'العنوان',lines:2),field(p,'الهاتف')],()async{await NovaSupabase.createBranch(s(r,'id'),name:a.text,address:b.text,phone:p.text);await refresh();});
    a.dispose();b.dispose();p.dispose();
  }
  Future<void> addProduct(Map<String,dynamic> r)async{
    final a=TextEditingController(),b=TextEditingController(),p=TextEditingController();
    await form('إضافة منتج',[field(a,'اسم المنتج'),field(b,'الوصف',lines:2),field(p,'السعر',type:TextInputType.number)],()async{final price=n(p.text);if(a.text.trim().isEmpty||price<=0)throw Exception('اكتب الاسم والسعر');await NovaSupabase.addMenuItemFull(s(r,'id'),name:a.text,description:b.text,price:price);await refresh();});
    a.dispose();b.dispose();p.dispose();
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
            if(d.mounted)setD(()=>{imageBytes=bytes,imageName=x.name});
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
            if(d.mounted)setD(()=>{imageBytes=bytes,imageName=p.name});
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
  Widget metric(String a,String b,IconData i,Color c)=>Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFE5E7EB))),child:Row(children:[CircleAvatar(backgroundColor:c.withValues(alpha:.1),child:Icon(i,color:c)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(color:ownerMuted,fontSize:10)),Text(b,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900))]))]));
  Widget pageTitle(String a,String b)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(b,style:const TextStyle(color:ownerMuted,fontSize:12))]);
  Widget card(Widget child)=>Container(padding:const EdgeInsets.all(15),margin:const EdgeInsets.only(bottom:10),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFE5E7EB))),child:child);
  Widget overview()=>ListView(children:[
    Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(gradient:const LinearGradient(colors:[ownerInk,Color(0xFF303746)]),borderRadius:BorderRadius.circular(30)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('NOVA CONTROL CENTER',style:TextStyle(color:Colors.white,fontSize:27,fontWeight:FontWeight.w900)),SizedBox(height:7),Text('إدارة كاملة للتطبيق من مكان واحد: مطاعم، منتجات، طلبات، عروض، محتوى ودعم.',style:TextStyle(color:Colors.white70,fontSize:12,height:1.5))])),
    const SizedBox(height:16),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.55,children:[metric('المبيعات',revenue.toStringAsFixed(0)+' ج.م',Icons.payments,Colors.green),metric('طلبات نشطة',active.toString(),Icons.local_shipping,ownerOrange),metric('تم التسليم',delivered.toString(),Icons.done_all,Colors.indigo),metric('المطاعم',restaurants.length.toString(),Icons.storefront,Colors.blue)]),
    const SizedBox(height:16),card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('تشغيل سريع',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900)),const SizedBox(height:10),Wrap(spacing:8,runSpacing:8,children:[ActionChip(label:const Text('مطعم جديد'),avatar:const Icon(Icons.add_business,color:ownerOrange),onPressed:addRestaurant),ActionChip(label:const Text('منتج جديد'),avatar:const Icon(Icons.add_circle,color:ownerOrange),onPressed:restaurants.isEmpty?null:()=>addProduct(restaurants.first)),ActionChip(label:const Text('كوبون'),avatar:const Icon(Icons.confirmation_number,color:ownerOrange),onPressed:coupon),ActionChip(label:const Text('عرض'),avatar:const Icon(Icons.campaign,color:ownerOrange),onPressed:offer),ActionChip(label:const Text('واجهة التطبيق'),avatar:const Icon(Icons.auto_awesome,color:ownerOrange),onPressed:()=>setState(()=>tab=5))])]))
  ]);
  Widget ordersPage()=>ListView(children:[pageTitle('إدارة الطلبات','متابعة وتغيير حالات الطلبات.'),const SizedBox(height:14),Row(children:[Expanded(child:metric('كل الطلبات',orders.length.toString(),Icons.receipt_long,ownerOrange)),const SizedBox(width:8),Expanded(child:metric('نشطة',active.toString(),Icons.bolt,Colors.green))]),const SizedBox(height:12),...orders.map((o)=>card(ListTile(title:Text(s(o,'restaurant_name'),style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('#'+id(o['id'])+' • '+s(o,'customer_name')),leading:const Icon(Icons.receipt_long,color:ownerOrange),trailing:PopupMenuButton<String>(onSelected:(x)async{await NovaSupabase.ownerUpdateOrderStatus(s(o,'id'),x);await refresh();},itemBuilder:(_)=>const['pending','accepted','preparing','ready','picked_up','on_the_way','delivered','cancelled'].map((x)=>PopupMenuItem(value:x,child:Text(x))).toList(),child:Chip(label:Text(s(o,'status')))))) )]);
  Widget restaurantsPage()=>ListView(children:[
    pageTitle('المطاعم والفروع','إضافة وتعديل المطاعم والفروع وإدارة منيو كل مطعم.'),
    const SizedBox(height:14),
    FilledButton.icon(onPressed:addRestaurant,icon:const Icon(Icons.add_business),label:const Text('إضافة مطعم جديد')),
    const SizedBox(height:12),
    ...restaurants.map((r)=>card(Column(children:[
      Row(children:[
        ClipRRect(borderRadius:BorderRadius.circular(16),child:Image.network((r['cover_url']??r['logo_url']??'').toString(),width:70,height:70,fit:BoxFit.cover,errorBuilder:(_,error,stack)=>Container(width:70,height:70,color:const Color(0xFFF1F2F4),child:const Icon(Icons.storefront,color:ownerOrange)))),
        const SizedBox(width:10),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(s(r,'name'),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),
          Text(s(r,'description'),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:ownerMuted,fontSize:10)),
        ])),
        PopupMenuButton<String>(
          onSelected:(x)async{if(x=='edit')await editRestaurant(r);if(x=='branch')await addBranch(r);if(x=='menu')await menu(r);if(x=='delete'){await NovaSupabase.deleteRestaurant(s(r,'id'));await refresh();}},
          itemBuilder:(_)=>const[
            PopupMenuItem(value:'edit',child:Text('تعديل')),
            PopupMenuItem(value:'branch',child:Text('إضافة فرع')),
            PopupMenuItem(value:'menu',child:Text('المنيو')),
            PopupMenuItem(value:'delete',child:Text('إيقاف')),
          ],
        ),
      ]),
      const SizedBox(height:10),
      Row(children:[
        Expanded(child:OutlinedButton.icon(onPressed:()=>addBranch(r),icon:const Icon(Icons.location_on_outlined),label:const Text('فرع جديد'))),
        const SizedBox(width:8),
        Expanded(child:FilledButton.icon(onPressed:()=>menu(r),icon:const Icon(Icons.restaurant_menu),label:const Text('المنيو'))),
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
  final Map<String,dynamic> restaurant;final List<Map<String,dynamic>> items;final Future<void> Function() onRefresh;
  const NovaMenuManager({super.key,required this.restaurant,required this.items,required this.onRefresh});
  @override State<NovaMenuManager> createState()=>_NovaMenuManagerState();
}
class _NovaMenuManagerState extends State<NovaMenuManager>{
  late List<Map<String,dynamic>> items;
  @override void initState(){super.initState();items=[...widget.items];}
  Future<void> reload()async{final x=await NovaSupabase.allRestaurantMenu(widget.restaurant['id'].toString());if(mounted)setState(()=>items=x);}
  Future<void> edit(Map<String,dynamic> x)async{
    final n=TextEditingController(text:(x['name']??'').toString()),p=TextEditingController(text:(x['price']??0).toString()),d=TextEditingController(text:(x['description']??'').toString());
    await showDialog(context:context,builder:(c)=>AlertDialog(title:const Text('تعديل المنتج'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:d,decoration:const InputDecoration(labelText:'الوصف')),TextField(controller:p,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'السعر'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إلغاء')),FilledButton(onPressed:()async{await NovaSupabase.updateMenuItem(x['id'].toString(),name:n.text,description:d.text,price:double.tryParse(p.text)??0);if(c.mounted)Navigator.pop(c);await reload();await widget.onRefresh();},child:const Text('حفظ'))]));
    n.dispose();p.dispose();d.dispose();
  }
  @override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:Text((widget.restaurant['name']??'المنيو').toString())),body:ListView(padding:const EdgeInsets.all(16),children:items.map((x)=>Card(child:ListTile(title:Text((x['name']??'').toString()),subtitle:Text((x['price']??0).toString()+' ج.م'),trailing:Wrap(children:[Switch(value:x['is_available']==true,onChanged:(b)async{await NovaSupabase.setMenuItemAvailability(x['id'].toString(),b);await reload();}),IconButton(onPressed:()=>edit(x),icon:const Icon(Icons.edit)),IconButton(onPressed:()async{await NovaSupabase.deleteMenuItem(x['id'].toString());await reload();await widget.onRefresh();},icon:const Icon(Icons.delete_outline,color:Colors.red))])))).toList())));
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
