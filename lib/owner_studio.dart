import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'core/supabase_service.dart';

const _ownerOrange = Color(0xFFFF5A36);
const _ownerInk = Color(0xFF151922);
const _ownerMuted = Color(0xFF747A86);

class OwnerStudioPage extends StatefulWidget {
  const OwnerStudioPage({super.key});
  @override State<OwnerStudioPage> createState()=>_OwnerStudioPageState();
}

class _OwnerStudioPageState extends State<OwnerStudioPage> with SingleTickerProviderStateMixin {
  List<Map<String,dynamic>> restaurants=[],coupons=[],offers=[],orders=[];
  bool loading=true;
  late final TabController tabs;

  @override void initState(){super.initState();tabs=TabController(length:4,vsync:this);load();}
  @override void dispose(){tabs.dispose();super.dispose();}

  void _snack(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));

  Future<void> load() async {
    if(mounted)setState(()=>loading=true);
    try{
      restaurants=await NovaSupabase.restaurants();
      coupons=await NovaSupabase.ownerCoupons();
      offers=await NovaSupabase.ownerOffers();
      orders=await NovaSupabase.ownerOrders();
    }catch(e){if(mounted)_snack('تعذر تحميل لوحة المالك: $e');}
    finally{if(mounted)setState(()=>loading=false);}
  }

  Future<XFile?> _pickImage() async => ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:90,maxWidth:1800);

  Future<void> addRestaurant() async {
    final n=TextEditingController(),d=TextEditingController(),p=TextEditingController(),fee=TextEditingController(text:'0'),min=TextEditingController(text:'0');
    XFile? image;
    await showDialog(context:context,builder:(x)=>StatefulBuilder(builder:(x,setD)=>AlertDialog(
      title:const Text('إضافة مطعم'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:n,decoration:const InputDecoration(labelText:'اسم المطعم *')),
        TextField(controller:d,decoration:const InputDecoration(labelText:'الوصف')),
        TextField(controller:p,decoration:const InputDecoration(labelText:'الهاتف')),
        TextField(controller:fee,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'رسوم التوصيل')),
        TextField(controller:min,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'الحد الأدنى')),
        const SizedBox(height:10),
        OutlinedButton.icon(onPressed:()async{image=await _pickImage();setD((){});},icon:const Icon(Icons.image_rounded),label:Text(image==null?'إضافة صورة المطعم':'تم اختيار الصورة ✓')),
      ])),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),
        FilledButton(onPressed:()async{
          if(n.text.trim().isEmpty){_snack('اكتب اسم المطعم');return;}
          try{
            final id=await NovaSupabase.createRestaurant(name:n.text,description:d.text,phone:p.text,deliveryFee:double.tryParse(fee.text)??0,minOrder:double.tryParse(min.text)??0);
            if(image!=null){final url=await NovaSupabase.uploadRestaurantCover(id,await image!.readAsBytes());if(url!=null)await NovaSupabase.updateRestaurant(id,coverUrl:url,logoUrl:url);}
            if(x.mounted)Navigator.pop(x);await load();
          }catch(e){if(x.mounted)_snack('تعذر إنشاء المطعم: $e');}
        },child:const Text('إنشاء المطعم'))
      ],
    )));
    n.dispose();d.dispose();p.dispose();fee.dispose();min.dispose();
  }

  Future<void> editRestaurant(Map<String,dynamic> r) async {
    final n=TextEditingController(text:'${r['name']??''}'),d=TextEditingController(text:'${r['description']??''}'),p=TextEditingController(text:'${r['phone']??''}'),fee=TextEditingController(text:'${r['delivery_fee']??0}'),min=TextEditingController(text:'${r['min_order']??0}');
    XFile? image;
    await showDialog(context:context,builder:(x)=>StatefulBuilder(builder:(x,setD)=>AlertDialog(
      title:Text('تعديل ${r['name']??'المطعم'}'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:n,decoration:const InputDecoration(labelText:'اسم المطعم')),
        TextField(controller:d,decoration:const InputDecoration(labelText:'الوصف')),
        TextField(controller:p,decoration:const InputDecoration(labelText:'الهاتف')),
        TextField(controller:fee,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'رسوم التوصيل')),
        TextField(controller:min,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'الحد الأدنى')),
        const SizedBox(height:10),
        OutlinedButton.icon(onPressed:()async{image=await _pickImage();setD((){});},icon:const Icon(Icons.photo_library_rounded),label:Text(image==null?'تغيير صورة المطعم':'الصورة الجديدة ✓')),
      ])),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),
        FilledButton(onPressed:()async{
          try{
            String? url;
            if(image!=null)url=await NovaSupabase.uploadRestaurantCover(r['id'].toString(),await image!.readAsBytes());
            await NovaSupabase.updateRestaurant(r['id'].toString(),name:n.text,description:d.text,phone:p.text,deliveryFee:double.tryParse(fee.text)??0,minOrder:double.tryParse(min.text)??0,coverUrl:url,logoUrl:url);
            if(x.mounted)Navigator.pop(x);await load();
          }catch(e){if(x.mounted)_snack('تعذر حفظ المطعم: $e');}
        },child:const Text('حفظ التعديلات'))
      ],
    )));
    n.dispose();d.dispose();p.dispose();fee.dispose();min.dispose();
  }

  Future<void> addBranch(String restaurantId) async {
    final n=TextEditingController(),a=TextEditingController(),p=TextEditingController();
    await showDialog(context:context,builder:(x)=>AlertDialog(title:const Text('إضافة فرع'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:n,decoration:const InputDecoration(labelText:'اسم الفرع')),TextField(controller:a,decoration:const InputDecoration(labelText:'العنوان')),TextField(controller:p,decoration:const InputDecoration(labelText:'الهاتف')),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),FilledButton(onPressed:()async{try{await NovaSupabase.createBranch(restaurantId,name:n.text,address:a.text,phone:p.text);if(x.mounted)Navigator.pop(x);await load();}catch(e){if(x.mounted)_snack('تعذر إضافة الفرع: $e');}},child:const Text('إضافة'))]));
    n.dispose();a.dispose();p.dispose();
  }

  Future<void> addMenuItem(String restaurantId) async {
    final n=TextEditingController(),d=TextEditingController(),p=TextEditingController();XFile? image;
    await showDialog(context:context,builder:(x)=>StatefulBuilder(builder:(x,setD)=>AlertDialog(title:const Text('إضافة وجبة / منتج'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:n,decoration:const InputDecoration(labelText:'اسم المنتج *')),TextField(controller:d,decoration:const InputDecoration(labelText:'الوصف')),TextField(controller:p,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'السعر *')),
      const SizedBox(height:8),OutlinedButton.icon(onPressed:()async{image=await _pickImage();setD((){});},icon:const Icon(Icons.image_rounded),label:Text(image==null?'إضافة صورة':'تم اختيار الصورة ✓'))
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),FilledButton(onPressed:()async{
      final price=double.tryParse(p.text);
      if(n.text.trim().isEmpty||price==null){_snack('اكتب اسم المنتج والسعر');return;}
      try{final id=await NovaSupabase.addMenuItemFull(restaurantId,name:n.text,price:price,description:d.text);if(image!=null){final url=await NovaSupabase.uploadMenuImage(id,await image!.readAsBytes());if(url!=null)await NovaSupabase.updateMenuItem(id,imageUrl:url);}if(x.mounted)Navigator.pop(x);}catch(e){if(x.mounted)_snack('تعذر إضافة المنتج: $e');}
    },child:const Text('إضافة'))]));
    n.dispose();d.dispose();p.dispose();
  }

  Future<void> editMenuItem(Map<String,dynamic> m) async {
    final n=TextEditingController(text:'${m['name']??''}'),d=TextEditingController(text:'${m['description']??''}'),p=TextEditingController(text:'${m['price']??0}');XFile? image;
    await showDialog(context:context,builder:(x)=>StatefulBuilder(builder:(x,setD)=>AlertDialog(title:const Text('تعديل المنتج'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:n,decoration:const InputDecoration(labelText:'اسم المنتج')),TextField(controller:d,decoration:const InputDecoration(labelText:'الوصف')),TextField(controller:p,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'السعر')),
      const SizedBox(height:8),OutlinedButton.icon(onPressed:()async{image=await _pickImage();setD((){});},icon:const Icon(Icons.photo_library_rounded),label:Text(image==null?'تغيير الصورة':'الصورة الجديدة ✓'))
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),FilledButton(onPressed:()async{
      try{String? url;if(image!=null)url=await NovaSupabase.uploadMenuImage(m['id'].toString(),await image!.readAsBytes());await NovaSupabase.updateMenuItem(m['id'].toString(),name:n.text,description:d.text,price:double.tryParse(p.text)??0,imageUrl:url);if(x.mounted)Navigator.pop(x);}catch(e){if(x.mounted)_snack('تعذر تعديل المنتج: $e');}
    },child:const Text('حفظ'))]));
    n.dispose();d.dispose();p.dispose();
  }

  Future<void> manageMenu(Map<String,dynamic> r) async {
    await showModalBottomSheet(context:context,isScrollControlled:true,showDragHandle:true,builder:(sheet)=>Directionality(textDirection:TextDirection.rtl,child:StatefulBuilder(builder:(sheet,setSheet){
      return FutureBuilder<List<Map<String,dynamic>>>(
        future:NovaSupabase.allRestaurantMenu(r['id'].toString()),
        builder:(c,snap){
          final items=snap.data??const <Map<String,dynamic>>[];
          return SizedBox(height:MediaQuery.sizeOf(sheet).height*.82,child:Column(children:[
            Padding(padding:const EdgeInsets.fromLTRB(18,8,18,12),child:Row(children:[Expanded(child:Text('منيو ${r['name']??'المطعم'}',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900))),IconButton(onPressed:()=>setSheet((){}),icon:const Icon(Icons.refresh_rounded))])),
            Expanded(child:ListView(padding:const EdgeInsets.all(18),children:[
              FilledButton.icon(onPressed:()async{await addMenuItem(r['id'].toString());if(sheet.mounted)setSheet((){});},icon:const Icon(Icons.add_rounded),label:const Text('إضافة وجبة / منتج')),
              const SizedBox(height:10),
              ...items.map((m)=>ListTile(
                leading:ClipRRect(borderRadius:BorderRadius.circular(10),child:Image.network((m['image_url']??'').toString(),width:52,height:52,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.fastfood,color:_ownerOrange))),
                title:Text((m['name']??'منتج').toString(),style:const TextStyle(fontWeight:FontWeight.w900)),
                subtitle:Text('${m['price']??0} ج.م • ${m['is_available']==true?'متاح':'مخفي'}'),
                trailing:PopupMenuButton<String>(onSelected:(v)async{if(v=='edit')await editMenuItem(m);if(v=='hide')await NovaSupabase.setMenuItemAvailability(m['id'].toString(),false);if(v=='show')await NovaSupabase.setMenuItemAvailability(m['id'].toString(),true);if(v=='delete')await NovaSupabase.deleteMenuItem(m['id'].toString());if(sheet.mounted)setSheet((){});},itemBuilder:(_)=>[
                  const PopupMenuItem(value:'edit',child:Text('تعديل')),
                  PopupMenuItem(value:m['is_available']==true?'hide':'show',child:Text(m['is_available']==true?'إخفاء':'إظهار')),
                  const PopupMenuItem(value:'delete',child:Text('حذف')),
                ]),
              ))
            ]))
          ]));
        },
      );
    })));
  }

  Future<void> addCoupon() async {
    final code=TextEditingController(),title=TextEditingController(),value=TextEditingController(),min=TextEditingController(text:'0');
    String type='percentage';
    await showDialog(context:context,builder:(x)=>StatefulBuilder(builder:(x,setD)=>AlertDialog(title:const Text('إضافة كوبون'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:code,decoration:const InputDecoration(labelText:'الكود مثل NOVA20')),TextField(controller:title,decoration:const InputDecoration(labelText:'عنوان العرض')),
      DropdownButtonFormField<String>(value:type,items:const[DropdownMenuItem(value:'percentage',child:Text('نسبة مئوية %')),DropdownMenuItem(value:'fixed',child:Text('خصم ثابت ج.م'))],onChanged:(v){if(v!=null)setD(()=>type=v);}),
      TextField(controller:value,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'قيمة الخصم')),TextField(controller:min,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'الحد الأدنى للطلب')),
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),FilledButton(onPressed:()async{try{await NovaSupabase.createCoupon(code:code.text,title:title.text,discountType:type,discountValue:double.parse(value.text),minOrder:double.tryParse(min.text)??0);if(x.mounted)Navigator.pop(x);await load();}catch(e){if(x.mounted)_snack('تعذر إنشاء الكوبون: $e');}},child:const Text('إضافة'))]));
    code.dispose();title.dispose();value.dispose();min.dispose();
  }

  Future<void> addOffer() async {
    final title=TextEditingController(),sub=TextEditingController(),target=TextEditingController();
    String type='coupon';XFile? image;String? couponId;
    await showDialog(context:context,builder:(x)=>StatefulBuilder(builder:(x,setD)=>AlertDialog(title:const Text('إضافة عرض في «عروض معمولة ليك»'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:title,decoration:const InputDecoration(labelText:'عنوان العرض')),TextField(controller:sub,decoration:const InputDecoration(labelText:'الوصف المختصر')),
      DropdownButtonFormField<String>(value:type,items:const[DropdownMenuItem(value:'coupon',child:Text('عرض + كوبون')),DropdownMenuItem(value:'restaurant',child:Text('يفتح مطعم')),DropdownMenuItem(value:'category',child:Text('يفتح تصنيف')),DropdownMenuItem(value:'map',child:Text('يفتح الخريطة'))],onChanged:(v){if(v!=null)setD(()=>type=v);}),
      if(type=='restaurant'||type=='category')TextField(controller:target,decoration:InputDecoration(labelText:type=='restaurant'?'اسم المطعم بالضبط':'اسم التصنيف مثل برجر')),
      if(type=='coupon'&&coupons.isNotEmpty)DropdownButtonFormField<String>(value:couponId,items:coupons.map((q)=>DropdownMenuItem(value:q['id'].toString(),child:Text((q['code']??'').toString()))).toList(),onChanged:(v)=>setD(()=>couponId=v),decoration:const InputDecoration(labelText:'الكوبون')),
      const SizedBox(height:8),OutlinedButton.icon(onPressed:()async{image=await _pickImage();setD((){});},icon:const Icon(Icons.image_rounded),label:Text(image==null?'إضافة صورة العرض':'تم اختيار الصورة ✓')),
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),FilledButton(onPressed:()async{
      try{final id=await NovaSupabase.createOffer(title:title.text,subtitle:sub.text,imageUrl:null,couponId:type=='coupon'?couponId:null);if(image!=null){final url=await NovaSupabase.uploadOfferImage(id,await image!.readAsBytes());if(url!=null)await NovaSupabase.updateOffer(id,{'image_url':url});}await NovaSupabase.updateOffer(id,{'target_type':type,'target_value':target.text.trim(),'target_label':type=='restaurant'?'فتح المطعم':type=='category'?'فتح التصنيف':type=='map'?'فتح الخريطة':'نسخ الكوبون'});if(x.mounted)Navigator.pop(x);await load();}catch(e){if(x.mounted)_snack('تعذر إنشاء العرض: $e');}
    },child:const Text('نشر العرض'))]));
    title.dispose();sub.dispose();target.dispose();
  }

  Widget restaurantCard(Map<String,dynamic> r)=>Card(
    margin:const EdgeInsets.only(bottom:12),
    child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
      ListTile(contentPadding:EdgeInsets.zero,
        leading:ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.network((r['logo_url']??r['cover_url']??'').toString(),width:62,height:62,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.storefront_rounded,color:_ownerOrange))),
        title:Text((r['name']??'مطعم').toString(),style:const TextStyle(fontWeight:FontWeight.w900)),
        subtitle:Text((r['description']??'').toString(),maxLines:2,overflow:TextOverflow.ellipsis),
        trailing:PopupMenuButton<String>(onSelected:(v)async{if(v=='edit')await editRestaurant(r);if(v=='menu')await manageMenu(r);if(v=='branch')await addBranch(r['id'].toString());if(v=='hide')await NovaSupabase.deleteRestaurant(r['id'].toString());await load();},itemBuilder:(_)=>const[
          PopupMenuItem(value:'edit',child:Text('تعديل المطعم')),PopupMenuItem(value:'menu',child:Text('إدارة المنيو')),PopupMenuItem(value:'branch',child:Text('إضافة فرع')),PopupMenuItem(value:'hide',child:Text('إخفاء المطعم'))
        ]),
      ),
      Row(children:[Expanded(child:OutlinedButton.icon(onPressed:()=>editRestaurant(r),icon:const Icon(Icons.edit_rounded),label:const Text('تعديل'))),const SizedBox(width:8),Expanded(child:FilledButton.icon(onPressed:()=>manageMenu(r),icon:const Icon(Icons.restaurant_menu_rounded),label:const Text('المنيو')))])
    ]));
  
  Widget promotions()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const Expanded(child:Text('الكوبونات',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900))),FilledButton.icon(onPressed:addCoupon,icon:const Icon(Icons.add),label:const Text('كوبون'))]),
    const SizedBox(height:10),
    ...coupons.map((q)=>ListTile(title:Text((q['code']??'').toString(),style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text((q['title']??'').toString()),trailing:Switch(value:q['is_active']==true,onChanged:(v)async{await NovaSupabase.updateCoupon(q['id'].toString(),{'is_active':v});await load();}))),
    const SizedBox(height:18),
    Row(children:[const Expanded(child:Text('عروض معمولة ليك',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900))),FilledButton.icon(onPressed:addOffer,icon:const Icon(Icons.add_photo_alternate_rounded),label:const Text('عرض'))]),
    const SizedBox(height:10),
    ...offers.map((o)=>Card(child:ListTile(leading:ClipRRect(borderRadius:BorderRadius.circular(10),child:Image.network((o['image_url']??'').toString(),width:62,height:48,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.local_offer_rounded,color:_ownerOrange))),title:Text((o['title']??'عرض').toString()),subtitle:Text((o['target_label']??o['target_type']??'').toString()),trailing:Switch(value:o['is_active']==true,onChanged:(v)async{await NovaSupabase.updateOffer(o['id'].toString(),{'is_active':v});await load();}))))
  ]);

  @override Widget build(BuildContext c){
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator(color:_ownerOrange)));
    return Scaffold(
      backgroundColor:Colors.white,
      appBar:AppBar(title:const Text('Nova Owner Studio',style:TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh_rounded))],bottom:TabBar(controller:tabs,isScrollable:true,tabs:const[Tab(text:'الرئيسية'),Tab(text:'المطاعم والمنيو'),Tab(text:'الكوبونات والعروض'),Tab(text:'الطلبات')])),
      body:TabBarView(controller:tabs,children:[
        ListView(padding:const EdgeInsets.all(16),children:[
          Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[_ownerInk,Color(0xFF343B4A)]),borderRadius:BorderRadius.circular(24)),child:const Text('مركز التحكم 👑',style:TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w900))),
          const SizedBox(height:14),Row(children:[Expanded(child:_stat('مطاعم',restaurants.length.toString(),Icons.storefront_rounded)),Expanded(child:_stat('طلبات',orders.length.toString(),Icons.receipt_long_rounded)),Expanded(child:_stat('عروض',offers.length.toString(),Icons.local_offer_rounded))])
        ]),
        ListView(padding:const EdgeInsets.all(16),children:[Row(children:[const Expanded(child:Text('المطاعم والمنيو',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900))),FilledButton.icon(onPressed:addRestaurant,icon:const Icon(Icons.add_business_rounded),label:const Text('مطعم جديد'))]),const SizedBox(height:14),...restaurants.map(restaurantCard)]),
        ListView(padding:const EdgeInsets.all(16),children:[promotions()]),
        ListView(padding:const EdgeInsets.all(16),children:[const Text('الطلبات',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:10),...orders.take(50).map((o)=>ListTile(title:Text((o['restaurant_name']??'مطعم').toString()),subtitle:Text((o['status']??'').toString()+' • '+(o['customer_name']??'').toString()),trailing:Text((o['id']??'').toString().substring(0,8),style:const TextStyle(color:_ownerOrange))))])
      ])
    );
  }
}

Widget _stat(String title,String value,IconData icon)=>Container(margin:const EdgeInsetsDirectional.only(end:8),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.black12)),child:Row(children:[Icon(icon,color:_ownerOrange),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(value,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),Text(title,style:const TextStyle(color:_ownerMuted,fontSize:9,fontWeight:FontWeight.w700))]))]));
