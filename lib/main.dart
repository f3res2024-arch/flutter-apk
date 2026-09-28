import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'core/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Never block the Android process from starting because a remote backend
  // configuration is temporarily invalid or unavailable.
  try {
    await NovaSupabase.initialize();
  } catch (_) {
    // NovaSupabase stores the initialization error for the auth UI.
  }

  runApp(const Nova());
}

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
  String get hours => 'حسب بيانات الفرع';
  String get phone => 'متاح من المصدر';
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

Future<String> resolveCurrentAddress() async {
  try {
    if(!await Geolocator.isLocationServiceEnabled()) return 'فعّل الموقع لإظهار عنوانك الحالي';
    var permission=await Geolocator.checkPermission();
    if(permission==LocationPermission.denied) permission=await Geolocator.requestPermission();
    if(permission==LocationPermission.denied||permission==LocationPermission.deniedForever) return 'اسمح لنوفا بالموقع لإظهار عنوانك الحالي';
    final p=await Geolocator.getCurrentPosition(locationSettings:const LocationSettings(accuracy:LocationAccuracy.medium));
    final uri=Uri.https('nominatim.openstreetmap.org','/reverse',{'lat':p.latitude.toString(),'lon':p.longitude.toString(),'format':'jsonv2','accept-language':'ar','zoom':'18','addressdetails':'1'});
    final response=await http.get(uri,headers:{'User-Agent':'NovaDelivery/2.1'});
    if(response.statusCode!=200)return 'موقعك الحالي • '+p.latitude.toStringAsFixed(5)+'، '+p.longitude.toStringAsFixed(5);
    final json=Map<String,dynamic>.from(jsonDecode(response.body) as Map);
    return (json['display_name']??'موقعك الحالي').toString();
  }catch(_){return 'اضغط لاختيار عنوانك الحالي';}
}


final appCopy = <String,String>{};
final appMedia = <String,String>{};
final favoriteRestaurants = <String>{};

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
    M('وجبة بازوكا سنايبر','3 قطع دجاج + بطاطس + خبز + كول سلو',225,'https://www.bazookaegy.com/public/uploads/meals/s_1738104474961829.jpg'),M('ريزو بقطع الدجاج','صوص حار أو باربيكيو',95,chicken),M('ساندوتش تشيكن رانش','دجاج مقرمش ورانش وموتزاريلا',145,chicken),M('أصابع الموتزاريلا','3 قطع مع صوص',50,chicken)
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
  @override State<Nova> createState()=>_NovaState();
}
class _NovaState extends State<Nova>{
  UserRole? role;
  bool logged=false;
  bool passwordRecovery=false;
  StreamSubscription<dynamic>? _authSubscription;
  @override void initState(){
    super.initState();
    _loadRealCatalog();
    if(NovaSupabase.initialized){
      if(NovaSupabase.client.auth.currentSession!=null) _restoreAuthenticatedUser();
      _authSubscription=NovaSupabase.client.auth.onAuthStateChange.listen((event){
        if(!mounted)return;
        if(event.event.toString().contains('passwordRecovery') || event.event.toString().contains('PASSWORD_RECOVERY')){setState(()=>passwordRecovery=true);}
        else if(event.event.toString().contains('signedIn') || event.event.toString().contains('SIGNED_IN') || event.event.toString().contains('tokenRefreshed') || event.event.toString().contains('TOKEN_REFRESHED')){_restoreAuthenticatedUser();}
        else if(event.event.toString().contains('signedOut') || event.event.toString().contains('SIGNED_OUT')){setState(()=>logged=false);}
      });
    }
  }
  Future<void> _loadRealCatalog() async {
    try {
      final copy=await NovaSupabase.appContent();
      for(final row in copy){ final k=(row['key']??'').toString(); final v=(row['text_value']??'').toString(); final image=(row['image_url']??'').toString(); if(k.isNotEmpty&&v.isNotEmpty)appCopy[k]=v; if(k.isNotEmpty&&image.isNotEmpty)appMedia[k]=image; }
    } catch(_) {}
    try {
      final rows=await NovaSupabase.catalog();
      if(rows.isEmpty)return;
      data
        ..clear()
        ..addAll(rows.map((r)=>R(
          (r['name']??'مطعم').toString(),
          (r['type']??'مطعم').toString(),
          (r['address']??'').toString(),
          (r['logo_url']??r['cover_url']??burger).toString(),
          'Nova Catalog',
          (r['rating'] as num?)?.toDouble()??0,
          (r['reviews'] as num?)?.toInt()??0,
          (r['lat'] as num?)?.toDouble()??31.0376,
          (r['lng'] as num?)?.toDouble()??31.3865,
          List<String>.from((r['branches']??[]) as List),
          ((r['menu']??[]) as List).map((m)=>M(
            (m['name']??'منتج').toString(),
            (m['description']??'').toString(),
            (m['price'] as num?)?.toDouble()??0,
            (m['image_url']??burger).toString(),
          )).toList(),
        )));
      if(mounted)setState((){});
    }catch(_){}
  }
  Future<void> _restoreAuthenticatedUser() async {
    final r=await NovaSupabase.currentUserRole();
    if(!mounted)return;
    final restored=r=='courier'?UserRole.courier:(r==null?null:UserRole.customer);
    if(restored!=null)setState(()=>role=restored);
    setState(()=>logged=r!=null);
  }
  @override void dispose(){_authSubscription?.cancel();super.dispose();}
  @override Widget build(BuildContext context)=>MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'نوفا ديليفري',
    theme:ThemeData(
      useMaterial3:true,brightness:Brightness.light,fontFamily:'sans',
      colorScheme:ColorScheme.fromSeed(seedColor:orange,brightness:Brightness.light,surface:Colors.white),
      scaffoldBackgroundColor:Colors.white,
      appBarTheme:const AppBarTheme(elevation:0,scrolledUnderElevation:0,backgroundColor:Colors.white,surfaceTintColor:Colors.transparent,centerTitle:true,titleTextStyle:TextStyle(fontSize:20,fontWeight:FontWeight.w900,color:ink),iconTheme:IconThemeData(color:ink)),
      cardTheme:CardThemeData(elevation:0,margin:EdgeInsets.zero,color:Colors.white,shadowColor:Color(0x12000000),surfaceTintColor:Colors.transparent,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(24))),
      inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Colors.white,contentPadding:const EdgeInsets.symmetric(horizontal:17,vertical:16),border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide(color:orange,width:1.4))),
      filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(backgroundColor:orange,foregroundColor:Colors.white,minimumSize:const Size.fromHeight(54),elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(17)),textStyle:const TextStyle(fontWeight:FontWeight.w900,fontSize:14))),
      outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(minimumSize:const Size.fromHeight(52),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(17)),side:const BorderSide(color:Color(0xFFE8E8EA)),textStyle:const TextStyle(fontWeight:FontWeight.w800))),
      navigationBarTheme:NavigationBarThemeData(height:76,elevation:0,backgroundColor:Colors.white,indicatorColor:orange.withValues(alpha:.14),labelTextStyle:const WidgetStatePropertyAll(TextStyle(fontSize:10,fontWeight:FontWeight.w800,color:ink))),
    ),
    home:Directionality(
      textDirection:TextDirection.rtl,
      child:logged
        ? (role==UserRole.courier?CourierDashboard(onLogout:()=>setState(()=>logged=false)):const Shell())
        : (passwordRecovery
          ? UpdatePasswordScreen(onDone:()=>setState(()=>passwordRecovery=false))
          : (role==null ? RoleChooser(onRole:(r)=>setState(()=>role=r)) : LoginScreen(role:role!,onBack:()=>setState(()=>role=null),onSuccess:()=>setState(()=>logged=true)))),
    ),
  );
}
enum UserRole { customer, courier }

class RoleChooser extends StatelessWidget{
  final ValueChanged<UserRole> onRole;
  const RoleChooser({super.key,required this.onRole});
  @override Widget build(BuildContext c)=>Scaffold(
    backgroundColor:Colors.white,
    body:SafeArea(child:SingleChildScrollView(
      padding:const EdgeInsets.fromLTRB(18,18,18,28),
      child:Column(children:[
        const Center(child:BrandHero()),
        const SizedBox(height:4),
        const SizedBox(height:18),
        Container(
          height:365,
          decoration:BoxDecoration(borderRadius:BorderRadius.circular(34),boxShadow:const[BoxShadow(color:Color(0x66000000),blurRadius:36,offset:Offset(0,18))]),
          child:ClipRRect(borderRadius:BorderRadius.circular(34),child:Stack(fit:StackFit.expand,children:[
            (appMedia['home_hero_image']??'').isEmpty ? Image.asset('assets/nova_rider.webp',fit:BoxFit.cover) : Image.network(appMedia['home_hero_image']!,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Image.asset('assets/nova_rider.webp',fit:BoxFit.cover)),
            const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(
              begin:Alignment.topCenter,end:Alignment.bottomCenter,
              colors:[Color(0x12000000),Color(0xE8000000)]))),
            const Positioned(right:20,bottom:22,left:20,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('أكلك. مزاجك.\nيوصل أسرع.',style:TextStyle(color:Colors.white,fontSize:31,height:1.02,fontWeight:FontWeight.w900)),
              SizedBox(height:8),
              Text('من المطعم لبابك بتجربة مصممة على مزاجك.',style:TextStyle(color:Colors.white70,fontSize:12,fontWeight:FontWeight.w600)),
            ])),
          ])),
        ),
        const SizedBox(height:16),
        const Row(children:[
          _Pill(icon:Icons.flash_on_rounded,text:'توصيل سريع'),
          SizedBox(width:7),_Pill(icon:Icons.location_on_rounded,text:'تتبع مباشر'),
          SizedBox(width:7),_Pill(icon:Icons.support_agent_rounded,text:'دعم 24/7'),
        ]),
        const SizedBox(height:20),
        const Align(alignment:Alignment.centerRight,child:Text('ابدأ رحلتك',style:TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.w900))),
        const SizedBox(height:10),
        _RoleButton(icon:Icons.person_rounded,title:'أنا عميل',sub:'اطلب، تابع، واستمتع',primary:true,onTap:()=>onRole(UserRole.customer)),
        const SizedBox(height:10),
        _RoleButton(icon:Icons.two_wheeler_rounded,title:'أنا مندوب',sub:'استقبل الطلبات واربح أكثر',primary:false,onTap:()=>onRole(UserRole.courier)),
      ]),
    )),
  );
}
class _Pill extends StatelessWidget{
  final IconData icon; final String text;
  const _Pill({required this.icon,required this.text});
  @override Widget build(BuildContext c)=>Expanded(child:Container(
    padding:const EdgeInsets.symmetric(vertical:11,horizontal:5),
    decoration:BoxDecoration(color:Colors.white.withValues(alpha:.055),borderRadius:BorderRadius.circular(16),border:Border.all(color:Colors.white10)),
    child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,color:orange,size:15),const SizedBox(width:4),Flexible(child:Text(text,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white70,fontSize:9,fontWeight:FontWeight.w800)))])
  ));
}
class _RoleButton extends StatelessWidget{
  final IconData icon; final String title,sub; final bool primary; final VoidCallback onTap;
  const _RoleButton({required this.icon,required this.title,required this.sub,required this.primary,required this.onTap});
  @override Widget build(BuildContext c)=>Material(
    color:Colors.transparent,
    child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(21),child:Container(
      padding:const EdgeInsets.all(13),
      decoration:BoxDecoration(
        gradient:primary?const LinearGradient(colors:[orange,Color(0xFFFF774F)]):null,
        color:primary?null:Colors.white.withValues(alpha:.055),
        borderRadius:BorderRadius.circular(21),border:Border.all(color:primary?Colors.transparent:Colors.white12),
        boxShadow:primary?const[BoxShadow(color:Color(0x44FF5A36),blurRadius:24,offset:Offset(0,8))]:null,
      ),
      child:Row(children:[
        Container(width:48,height:48,decoration:BoxDecoration(color:primary?Colors.white.withValues(alpha:.18):orange.withValues(alpha:.13),shape:BoxShape.circle),child:Icon(icon,color:Colors.white,size:24)),
        const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(title,style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.w900)),
          const SizedBox(height:2),Text(sub,style:TextStyle(color:primary?Colors.white70:Colors.white54,fontSize:10)),
        ])),
        Container(width:34,height:34,decoration:BoxDecoration(color:Colors.white.withValues(alpha:.08),shape:BoxShape.circle),child:const Icon(Icons.arrow_back_rounded,color:Colors.white,size:17)),
      ]),
    )),
  );
}
class BrandHero extends StatelessWidget {
  const BrandHero({super.key});
  @override Widget build(BuildContext c)=>Center(child:RichText(text:TextSpan(children:[
    TextSpan(text:'نوفا ',style:TextStyle(color:ink,fontSize:21,fontWeight:FontWeight.w900)),
    TextSpan(text:'ديليفري',style:TextStyle(color:orange,fontSize:21,fontWeight:FontWeight.w900)),
  ])));
}

class LoginScreen extends StatefulWidget {
  final UserRole role; final VoidCallback onBack,onSuccess;
  const LoginScreen({super.key,required this.role,required this.onBack,required this.onSuccess});
  @override State<LoginScreen> createState()=>_LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen>{
  bool hide=true,busy=false,googleBusy=false;
  final email=TextEditingController(),pass=TextEditingController();
  @override void dispose(){email.dispose();pass.dispose();super.dispose();}
  Future<void> submit() async {
    final e=email.text.trim(),p=pass.text;
    if(e.isEmpty||!e.contains('@')){snack(context,'اكتب بريد إلكتروني صحيح');return;}
    if(p.length<6){snack(context,'كلمة المرور يجب أن تكون 6 أحرف على الأقل');return;}
    setState(()=>busy=true);
    try{
      if(!NovaSupabase.initialized){
        throw (NovaSupabase.initializationError ?? const AuthException('خدمة الحساب غير مهيأة.'));
      }
      final res=await NovaSupabase.signIn(email:e,password:p);
      if(res.user==null || res.session==null){
        throw const AuthException('تعذر إنشاء جلسة تسجيل الدخول.');
      }
      if(mounted)widget.onSuccess();
    }on AuthException catch(e){
      if(mounted)snack(context,_authMessage(e.message));
    }catch(e){
      if(mounted)snack(context,'خطأ الاتصال: ${e.toString().replaceFirst('Exception: ', '')}');
    }
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> google() async {
    setState(()=>googleBusy=true);
    try{await NovaSupabase.signInWithGoogle();}
    on AuthException catch(e){if(mounted)snack(context,_authMessage(e.message));}
    catch(_){if(mounted)snack(context,'تعذر فتح تسجيل Google. تأكد من إعداد OAuth في Supabase.');}
    finally{if(mounted)setState(()=>googleBusy=false);}
  }
  @override Widget build(BuildContext c)=>AuthScaffold(
    onBack:widget.onBack,eyebrow:'تسجيل الدخول',
    title:'مرحباً بك',
    subtitle:widget.role==UserRole.customer?'سجّل دخولك وخلّي أكلك علينا.':'سجّل دخولك واستقبل طلباتك بسهولة.',
    child:Column(children:[
      AuthField(controller:email,label:'البريد الإلكتروني',hint:'name@example.com',icon:Icons.mail_outline_rounded,keyboardType:TextInputType.emailAddress),
      const SizedBox(height:13),
      AuthField(controller:pass,label:'كلمة المرور',hint:'••••••••',icon:Icons.lock_outline_rounded,obscureText:hide,suffix:IconButton(onPressed:()=>setState(()=>hide=!hide),icon:Icon(hide?Icons.visibility_outlined:Icons.visibility_off_outlined))),
      Align(alignment:Alignment.centerLeft,child:TextButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>ForgotPasswordScreen(role:widget.role))),child:const Text('نسيت كلمة المرور؟',style:TextStyle(color:orange,fontWeight:FontWeight.w800)))),
      const SizedBox(height:3),
      FilledButton(onPressed:busy?null:submit,child:busy?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('تسجيل الدخول')),
      const SizedBox(height:18),
      Row(children:[const Expanded(child:Divider()),Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Text('أو',style:TextStyle(color:muted,fontWeight:FontWeight.w700))),const Expanded(child:Divider())]),
      const SizedBox(height:15),
      OutlinedButton.icon(onPressed:googleBusy?null:google,icon:googleBusy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const _GoogleMark(),label:const Text('المتابعة باستخدام Google')),
      const SizedBox(height:18),
      Row(mainAxisAlignment:MainAxisAlignment.center,children:[const Text('ليس لديك حساب؟',style:TextStyle(color:muted)),TextButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>SignupScreen(role:widget.role))),child:const Text('إنشاء حساب',style:TextStyle(color:orange,fontWeight:FontWeight.w900)))])
    ]),
  );
}

class SignupScreen extends StatefulWidget{
  final UserRole role;
  const SignupScreen({super.key,required this.role});
  @override State<SignupScreen> createState()=>_SignupScreenState();
}
class _SignupScreenState extends State<SignupScreen>{
  bool hide=true,confirmHide=true,busy=false;
  final name=TextEditingController(),phone=TextEditingController(),email=TextEditingController(),pass=TextEditingController(),confirm=TextEditingController();
  @override void dispose(){name.dispose();phone.dispose();email.dispose();pass.dispose();confirm.dispose();super.dispose();}
  Future<void> createAccount() async {
    final n=name.text.trim(),ph=phone.text.trim(),e=email.text.trim(),p=pass.text;
    if(n.length<2){snack(context,'اكتب اسمك بالكامل');return;}
    if(ph.length<8){snack(context,'اكتب رقم هاتف صحيح');return;}
    if(e.isEmpty||!e.contains('@')){snack(context,'اكتب بريد إلكتروني صحيح');return;}
    if(p.length<6){snack(context,'كلمة المرور يجب أن تكون 6 أحرف على الأقل');return;}
    if(p!=confirm.text){snack(context,'كلمتا المرور غير متطابقتين');return;}
    setState(()=>busy=true);
    try{
      final res=await NovaSupabase.signUp(email:e,password:p,role:widget.role.name,fullName:n,phone:ph);
      if(!mounted)return;
      if(res.session!=null){
        if(mounted)Navigator.pop(context);
        if(mounted)snack(context,'تم إنشاء حسابك بنجاح 🎉');
      }else{
        if(!mounted)return;
        await Navigator.push(context,MaterialPageRoute(builder:(_)=>EmailOtpScreen(email:e,role:widget.role)));
        if(mounted && NovaSupabase.session!=null)Navigator.pop(context);
      }
    }on AuthException catch(e){if(mounted)snack(context,_authMessage(e.message));}
    catch(_){if(mounted)snack(context,'تعذر إنشاء الحساب. حاول مرة أخرى.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext c)=>AuthScaffold(
    onBack:()=>Navigator.pop(c),eyebrow:'حساب جديد',title:'ابدأ مع نوفا',subtitle:'أنشئ حسابك في ثواني وابدأ أول طلب.',
    child:Column(children:[
      AuthField(controller:name,label:'الاسم',hint:'اكتب اسمك بالكامل',icon:Icons.person_outline_rounded),
      const SizedBox(height:13),
      AuthField(controller:phone,label:'رقم الهاتف',hint:'01xxxxxxxxx',icon:Icons.phone_outlined,keyboardType:TextInputType.phone),
      const SizedBox(height:13),
      AuthField(controller:email,label:'البريد الإلكتروني',hint:'name@example.com',icon:Icons.mail_outline_rounded,keyboardType:TextInputType.emailAddress),
      const SizedBox(height:13),
      AuthField(controller:pass,label:'كلمة المرور',hint:'6 أحرف أو أكثر',icon:Icons.lock_outline_rounded,obscureText:hide,suffix:IconButton(onPressed:()=>setState(()=>hide=!hide),icon:Icon(hide?Icons.visibility_outlined:Icons.visibility_off_outlined))),
      const SizedBox(height:13),
      AuthField(controller:confirm,label:'تأكيد كلمة المرور',hint:'أعد كتابة كلمة المرور',icon:Icons.verified_user_outlined,obscureText:confirmHide,suffix:IconButton(onPressed:()=>setState(()=>confirmHide=!confirmHide),icon:Icon(confirmHide?Icons.visibility_outlined:Icons.visibility_off_outlined))),
      const SizedBox(height:18),
      FilledButton(onPressed:busy?null:createAccount,child:busy?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('إنشاء الحساب')),
      const SizedBox(height:12),const Text('بإنشاء الحساب أنت توافق على شروط الاستخدام وسياسة الخصوصية.',textAlign:TextAlign.center,style:TextStyle(color:muted,fontSize:11,height:1.5)),
    ]),
  );
}

class EmailOtpScreen extends StatefulWidget{
  final String email;
  final UserRole role;
  const EmailOtpScreen({super.key,required this.email,required this.role});
  @override State<EmailOtpScreen> createState()=>_EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen>{
  final code=TextEditingController();
  bool busy=false,resending=false;
  @override void dispose(){code.dispose();super.dispose();}

  Future<void> verify() async {
    final token=code.text.trim();
    if(token.length!=6){snack(context,'اكتب رمز التحقق المكوّن من 6 أرقام');return;}
    setState(()=>busy=true);
    try{
      final res=await NovaSupabase.verifyEmailOtp(email:widget.email,token:token);
      if(res.session!=null){
        if(mounted){
          snack(context,'تم تأكيد بريدك وإنشاء حسابك بنجاح 🎉');
          Navigator.pop(context);
        }
      }else if(mounted){
        snack(context,'تم التحقق لكن لم يتم إنشاء جلسة. حاول تسجيل الدخول.');
        Navigator.pop(context);
      }
    }on AuthException catch(e){if(mounted)snack(context,_authMessage(e.message));}
    catch(_){if(mounted)snack(context,'رمز التحقق غير صحيح أو انتهت صلاحيته.');}
    finally{if(mounted)setState(()=>busy=false);}
  }

  Future<void> resend() async {
    if(resending)return;
    setState(()=>resending=true);
    try{
      await NovaSupabase.resendSignupOtp(widget.email);
      if(mounted)snack(context,'تم إرسال رمز جديد إلى بريدك الإلكتروني.');
    }on AuthException catch(e){if(mounted)snack(context,_authMessage(e.message));}
    catch(_){if(mounted)snack(context,'تعذر إرسال رمز جديد حالياً.');}
    finally{if(mounted)setState(()=>resending=false);}
  }

  @override Widget build(BuildContext c)=>AuthScaffold(
    onBack:()=>Navigator.pop(c),
    eyebrow:'تأكيد الحساب',
    title:'أدخل رمز التحقق',
    subtitle:'تم إرسال رمز مكوّن من 6 أرقام إلى بريدك الإلكتروني.',
    child:Column(children:[
      Container(
        width:double.infinity,
        padding:const EdgeInsets.all(16),
        decoration:BoxDecoration(color:orange.withValues(alpha:.07),borderRadius:BorderRadius.circular(18)),
        child:Row(children:[
          const Icon(Icons.mark_email_read_rounded,color:orange),
          const SizedBox(width:10),
          Expanded(child:Text(widget.email,textDirection:TextDirection.ltr,textAlign:TextAlign.left,style:const TextStyle(fontWeight:FontWeight.w800))),
        ]),
      ),
      const SizedBox(height:18),
      TextField(
        controller:code,
        autofocus:true,
        keyboardType:TextInputType.number,
        textDirection:TextDirection.ltr,
        textAlign:TextAlign.center,
        maxLength:6,
        inputFormatters:[FilteringTextInputFormatter.digitsOnly],
        style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900,letterSpacing:8),
        decoration:const InputDecoration(
          labelText:'رمز التحقق',
          hintText:'000000',
          counterText:'',
          prefixIcon:Icon(Icons.password_rounded),
        ),
        onSubmitted:(_)=>verify(),
      ),
      const SizedBox(height:18),
      FilledButton(
        onPressed:busy?null:verify,
        child:busy?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('متابعة'),
      ),
      const SizedBox(height:10),
      TextButton.icon(
        onPressed:resending?null:resend,
        icon:resending?const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:orange)):const Icon(Icons.refresh_rounded),
        label:const Text('إرسال رمز جديد'),
      ),
      const SizedBox(height:4),
      const Text('لو لم يصل الرمز، راجع البريد غير المرغوب فيه وتأكد من صحة البريد.',textAlign:TextAlign.center,style:TextStyle(color:muted,fontSize:11,height:1.5)),
    ]),
  );
}

class ForgotPasswordScreen extends StatefulWidget{
  final UserRole role;
  const ForgotPasswordScreen({super.key,required this.role});
  @override State<ForgotPasswordScreen> createState()=>_ForgotPasswordScreenState();
}
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>{
  bool busy=false;
  final email=TextEditingController();
  @override void dispose(){email.dispose();super.dispose();}
  Future<void> send() async {
    final e=email.text.trim();
    if(e.isEmpty||!e.contains('@')){snack(context,'اكتب بريد إلكتروني صحيح');return;}
    setState(()=>busy=true);
    try{
      await NovaSupabase.sendPasswordReset(e);
      if(mounted)await showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('تم إرسال رابط الاستعادة'),content:Text('لو البريد $e مسجل، هتوصلك رسالة استعادة كلمة المرور. افتح الرابط من نفس الهاتف للعودة إلى نوفا.'),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('حسناً'))]));
    }on AuthException catch(e){if(mounted)snack(context,_authMessage(e.message));}
    catch(_){if(mounted)snack(context,'تعذر إرسال رسالة الاستعادة. حاول مرة أخرى.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext c)=>AuthScaffold(
    onBack:()=>Navigator.pop(c),eyebrow:'استعادة الحساب',title:'نسيت كلمة المرور؟',subtitle:'اكتب بريدك وسنرسل لك رابطاً آمناً لإعادة تعيينها.',
    child:Column(children:[
      AuthField(controller:email,label:'البريد الإلكتروني',hint:'name@example.com',icon:Icons.mail_outline_rounded,keyboardType:TextInputType.emailAddress),
      const SizedBox(height:18),FilledButton(onPressed:busy?null:send,child:busy?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('إرسال رابط الاستعادة')),
    ]),
  );
}

class UpdatePasswordScreen extends StatefulWidget{
  final VoidCallback onDone;
  const UpdatePasswordScreen({super.key,required this.onDone});
  @override State<UpdatePasswordScreen> createState()=>_UpdatePasswordScreenState();
}
class _UpdatePasswordScreenState extends State<UpdatePasswordScreen>{
  bool hide=true,busy=false;
  final pass=TextEditingController(),confirm=TextEditingController();
  @override void dispose(){pass.dispose();confirm.dispose();super.dispose();}
  Future<void> update() async {
    if(pass.text.length<6){snack(context,'كلمة المرور يجب أن تكون 6 أحرف على الأقل');return;}
    if(pass.text!=confirm.text){snack(context,'كلمتا المرور غير متطابقتين');return;}
    setState(()=>busy=true);
    try{await NovaSupabase.updatePassword(pass.text);if(mounted){snack(context,'تم تغيير كلمة المرور بنجاح 🎉');widget.onDone();}}
    on AuthException catch(e){if(mounted)snack(context,_authMessage(e.message));}
    catch(_){if(mounted)snack(context,'تعذر تغيير كلمة المرور.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext c)=>AuthScaffold(
    onBack:widget.onDone,eyebrow:'حماية الحساب',title:'أنشئ كلمة مرور جديدة',subtitle:'اختار كلمة مرور قوية لا تستخدمها في حسابات أخرى.',
    child:Column(children:[
      AuthField(controller:pass,label:'كلمة المرور الجديدة',hint:'6 أحرف أو أكثر',icon:Icons.lock_reset_rounded,obscureText:hide,suffix:IconButton(onPressed:()=>setState(()=>hide=!hide),icon:Icon(hide?Icons.visibility_outlined:Icons.visibility_off_outlined))),
      const SizedBox(height:13),AuthField(controller:confirm,label:'تأكيد كلمة المرور',hint:'أعد كتابة كلمة المرور',icon:Icons.verified_user_outlined,obscureText:true),
      const SizedBox(height:18),FilledButton(onPressed:busy?null:update,child:busy?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('حفظ كلمة المرور')),
    ]),
  );
}

class AuthScaffold extends StatelessWidget{
  final VoidCallback onBack; final String eyebrow,title,subtitle; final Widget child;
  const AuthScaffold({super.key,required this.onBack,required this.eyebrow,required this.title,required this.subtitle,required this.child});
  @override Widget build(BuildContext c){
    final bottom=MediaQuery.viewInsetsOf(c).bottom;
    return Scaffold(
      resizeToAvoidBottomInset:true,
      appBar:AppBar(
        leading:IconButton(onPressed:onBack,icon:const Icon(Icons.arrow_forward_rounded)),
        title:const BrandHero(),
      ),
      body:SafeArea(
        child:LayoutBuilder(
          builder:(context,box)=>SingleChildScrollView(
            padding:EdgeInsets.fromLTRB(20,10,20,24+bottom),
            child:ConstrainedBox(
              constraints:BoxConstraints(minHeight:box.maxHeight-34,maxWidth:560),
              child:Center(
                child:Container(
                  width:double.infinity,
                  padding:const EdgeInsets.all(22),
                  decoration:BoxDecoration(
                    color:Theme.of(context).colorScheme.surface,
                    borderRadius:BorderRadius.circular(30),
                    border:Border.all(color:Theme.of(context).dividerColor.withValues(alpha:.35)),
                    boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.16),blurRadius:30,offset:const Offset(0,18))],
                  ),
                  child:Column(
                    crossAxisAlignment:CrossAxisAlignment.start,
                    mainAxisAlignment:MainAxisAlignment.center,
                    children:[
                      Container(
                        padding:const EdgeInsets.symmetric(horizontal:11,vertical:7),
                        decoration:BoxDecoration(color:orange.withValues(alpha:.10),borderRadius:BorderRadius.circular(30)),
                        child:Text(eyebrow,style:const TextStyle(color:orange,fontSize:11,fontWeight:FontWeight.w900)),
                      ),
                      const SizedBox(height:14),
                      Text(title,style:const TextStyle(fontSize:30,fontWeight:FontWeight.w900,height:1.1)),
                      const SizedBox(height:7),
                      Text(subtitle,style:const TextStyle(color:muted,fontSize:13,height:1.5)),
                      const SizedBox(height:23),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthField extends StatelessWidget{
  final TextEditingController controller; final String label,hint; final IconData icon; final TextInputType? keyboardType; final bool obscureText; final Widget? suffix;
  const AuthField({super.key,required this.controller,required this.label,required this.hint,required this.icon,this.keyboardType,this.obscureText=false,this.suffix});
  @override Widget build(BuildContext c){
    final isEmail=keyboardType==TextInputType.emailAddress;
    return TextField(
      controller:controller,
      keyboardType:keyboardType,
      textDirection:isEmail?TextDirection.ltr:TextDirection.rtl,
      textAlign:isEmail?TextAlign.left:TextAlign.right,
      textCapitalization:TextCapitalization.none,
      autocorrect:false,
      enableSuggestions:!isEmail,
      inputFormatters:isEmail?[FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._+\\-]'))]:null,
      obscureText:obscureText,
      textInputAction:TextInputAction.next,
      decoration:InputDecoration(
        labelText:label,
        hintText:hint,
        prefixIcon:Icon(icon),
        suffixIcon:suffix,
        alignLabelWithHint:true,
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget{
  const _GoogleMark();
  @override Widget build(BuildContext c)=>Image.network('https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.png',width:22,height:22,errorBuilder:(_,__,___)=>const Text('G',style:TextStyle(color:Color(0xFF4285F4),fontWeight:FontWeight.w900,fontSize:19)));
}
String _authMessage(String message){
  final m=message.toLowerCase();
  if(m.contains('إعدادات الخادم غير موجودة'))return 'نسخة التطبيق الحالية لا تحتوي إعدادات الخادم. ثبّت أحدث APK.';
  if(m.contains('خدمة الحساب غير مهيأة'))return 'خدمة الحساب لم تبدأ بشكل صحيح. ثبّت أحدث APK وأعد فتح التطبيق.';
  if(m.contains('invalid login credentials'))return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
  if(m.contains('email not confirmed'))return 'أكد بريدك الإلكتروني أولاً من الرسالة التي وصلتك.';
  if(m.contains('user already registered'))return 'هذا البريد مسجل بالفعل. جرّب تسجيل الدخول.';
  if(m.contains('password'))return 'كلمة المرور غير صالحة أو لا تستوفي الشروط.';
  if(m.contains('rate limit'))return 'طلبات كثيرة حالياً. انتظر قليلاً ثم حاول مرة أخرى.';
  if(m.contains('network') || m.contains('socket') || m.contains('connection'))return 'تعذر الاتصال بخادم الحساب. تحقق من الإنترنت وحاول مرة أخرى.';
  return 'تعذر تنفيذ العملية حالياً. حاول مرة أخرى.';
}

class CourierDashboard extends StatefulWidget {
  final VoidCallback onLogout;
  const CourierDashboard({super.key,required this.onLogout});
  @override State<CourierDashboard> createState()=>_CourierDashboardState();
}

class _CourierDashboardState extends State<CourierDashboard>{
  bool online=true;
  int tab=0;
  bool loadingOrders=true;
  bool actionBusy=false;
  List<Map<String,dynamic>> orders=[];
  dynamic realtimeChannel;

  @override void initState(){super.initState();refreshOrders();}
  @override void dispose(){
    final channel=realtimeChannel;
    if(channel!=null) channel.unsubscribe();
    super.dispose();
  }

  Future<void> refreshOrders() async {
    if(!mounted) return;
    setState(()=>loadingOrders=true);
    try{
      if(NovaSupabase.configured && NovaSupabase.client.auth.currentUser!=null){
        final rows=await NovaSupabase.courierOrders();
        if(!mounted) return;
        setState(()=>orders=rows);
        realtimeChannel ??= NovaSupabase.watchCourierOrders(refreshOrders);
      }else{
        setState(()=>orders=[
          {
            'id':'demo-2850','customer_name':'أحمد محمد','restaurant_name':'ماكدونالدز',
            'total':312,'delivery_fee':52,'status':'pending',
            'pickup_address':'فرع جامعة المنصورة — شارع الجمهورية',
            'pickup_lat':31.0430,'pickup_lng':31.3560,
            'delivery_address':'حي الجامعة — المنصورة',
            'customer_lat':31.0474,'customer_lng':31.3499,
            'notes':'الدفع عند الاستلام',
            'order_items':[
              {'item_name':'بيج ماك','quantity':1,'unit_price':180},
              {'item_name':'بطاطس مقلية','quantity':2,'unit_price':66},
            ],
          },
          {
            'id':'demo-2851','customer_name':'محمد علي','restaurant_name':'بازوكا',
            'total':358,'delivery_fee':68,'status':'pending',
            'pickup_address':'فرع شارع الجيش — أمام الاستاد',
            'pickup_lat':31.0470,'pickup_lng':31.3544,
            'delivery_address':'توريل — المنصورة',
            'customer_lat':31.0407,'customer_lng':31.3638,
            'notes':'اتصل عند الوصول',
            'order_items':[
              {'item_name':'وجبة بازوكا سنايبر','quantity':1,'unit_price':210},
              {'item_name':'ساندوتش تشيكن رانش','quantity':1,'unit_price':148},
            ],
          },
        ]);
      }
    }catch(e){
      if(mounted) snack(context,'تعذر تحديث الطلبات: '+e.toString());
    }finally{
      if(mounted) setState(()=>loadingOrders=false);
    }
  }

  Future<void> acceptOrder(Map<String,dynamic> order) async {
    if(actionBusy) return;
    setState(()=>actionBusy=true);
    try{
      Map<String,dynamic> claimed=order;
      if(NovaSupabase.configured && NovaSupabase.client.auth.currentUser!=null){
        final result=await NovaSupabase.claimOrder(order['id'].toString());
        if(result==null) throw Exception('الطلب تم أخذه بواسطة مندوب آخر');
        claimed={...order,...result};
      }
      if(!mounted) return;
      setState(()=>orders.removeWhere((x)=>x['id'].toString()==order['id'].toString()));
      Navigator.push(context,MaterialPageRoute(builder:(_)=>CourierRoutePage(order:claimed)));
    }catch(e){
      if(mounted) snack(context,'لم يتم قبول الطلب: '+e.toString());
      await refreshOrders();
    }finally{
      if(mounted) setState(()=>actionBusy=false);
    }
  }

  Future<void> rejectOrder(Map<String,dynamic> order) async {
    if(actionBusy) return;
    setState(()=>actionBusy=true);
    try{
      if(NovaSupabase.configured && NovaSupabase.client.auth.currentUser!=null){
        await NovaSupabase.rejectOrder(order['id'].toString());
      }
      if(mounted){
        setState(()=>orders.removeWhere((x)=>x['id'].toString()==order['id'].toString()));
        snack(context,'تم رفض الطلب وسيظل متاحًا لباقي المناديب');
      }
    }catch(e){
      if(mounted) snack(context,'تعذر رفض الطلب: '+e.toString());
    }finally{
      if(mounted) setState(()=>actionBusy=false);
    }
  }

  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const BrandHero(),actions:[
      IconButton(onPressed:refreshOrders,icon:const Icon(Icons.refresh_rounded)),
      IconButton(onPressed:widget.onLogout,icon:const Icon(Icons.logout)),
    ]),
    body:SafeArea(child:IndexedStack(index:tab,children:[dashboard(),earnings(),account()])),
    bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[
      NavigationDestination(icon:Icon(Icons.dashboard_outlined),label:'الطلبات'),
      NavigationDestination(icon:Icon(Icons.account_balance_wallet_outlined),label:'الأرباح'),
      NavigationDestination(icon:Icon(Icons.person_outline),label:'حسابي'),
    ]),
  );

  Widget dashboard()=>RefreshIndicator(
    onRefresh:refreshOrders,
    child:ListView(
      physics:const AlwaysScrollableScrollPhysics(),
      padding:const EdgeInsets.all(18),
      children:[
        Container(
          padding:const EdgeInsets.all(18),
          decoration:BoxDecoration(color:ink,borderRadius:BorderRadius.circular(24)),
          child:Row(children:[
            const Icon(Icons.two_wheeler,color:orange,size:38),const SizedBox(width:12),
            const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('حالة المندوب',style:TextStyle(color:Colors.white70)),
              Text('متاح لاستقبال الطلبات',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:17)),
            ])),
            Switch(value:online,onChanged:(v)=>setState(()=>online=v)),
          ]),
        ),
        const SizedBox(height:20),
        Row(children:[
          const Expanded(child:Text('طلبات جديدة',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900))),
          if(orders.isNotEmpty) Chip(label:Text(orders.length.toString()+' متاح')),
        ]),
        const SizedBox(height:10),
        if(loadingOrders && orders.isEmpty)
          const Padding(padding:EdgeInsets.all(30),child:Center(child:CircularProgressIndicator(color:orange)))
        else if(!online)
          const EmptyCourierState(icon:Icons.pause_circle_outline,title:'أنت غير متاح الآن',sub:'فعّل حالة التوفر لاستقبال طلبات جديدة')
        else if(orders.isEmpty)
          const EmptyCourierState(icon:Icons.delivery_dining,title:'لا توجد طلبات جديدة',sub:'أي طلب جديد سيظهر هنا فورًا')
        else
          ...orders.map(orderCard),
      ],
    ),
  );

  Widget orderCard(Map<String,dynamic> o){
    final items=List<Map<String,dynamic>>.from((o['order_items'] as List?)??const[]);
    final total=_money(o['total']);
    final fee=_money(o['delivery_fee']);
    final customer=(o['customer_name']??'عميل نوفا').toString();
    final shop=(o['restaurant_name']??'مطعم نوفا').toString();
    return Container(
      margin:const EdgeInsets.only(bottom:13),
      padding:const EdgeInsets.all(16),
      decoration:BoxDecoration(
        color:Theme.of(context).colorScheme.surface,
        borderRadius:BorderRadius.circular(22),
        border:Border.all(color:orange.withValues(alpha:.16)),
      ),
      child:Column(children:[
        Row(children:[
          Container(width:48,height:48,decoration:BoxDecoration(color:orange.withValues(alpha:.11),borderRadius:BorderRadius.circular(15)),child:const Icon(Icons.delivery_dining,color:orange,size:27)),
          const SizedBox(width:11),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(shop,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),
            Text('العميل: '+customer,style:const TextStyle(color:muted,fontSize:11)),
            Text('#'+_shortId(o['id']),style:const TextStyle(color:muted,fontSize:10)),
          ])),
          Text(total.toStringAsFixed(0)+' ج.م',style:const TextStyle(color:orange,fontWeight:FontWeight.w900,fontSize:17)),
        ]),
        const SizedBox(height:12),
        Container(
          padding:const EdgeInsets.all(12),
          decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha:.55),borderRadius:BorderRadius.circular(16)),
          child:Column(children:[
            Row(children:[const Icon(Icons.storefront_outlined,color:orange,size:18),const SizedBox(width:7),Expanded(child:Text((o['pickup_address']??'عنوان المطعم').toString(),style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700)))]),
            const Padding(padding:EdgeInsets.symmetric(vertical:7),child:Divider(height:1)),
            Row(children:[const Icon(Icons.person_pin_circle_outlined,color:orange,size:18),const SizedBox(width:7),Expanded(child:Text((o['delivery_address']??'عنوان العميل').toString(),style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700)))]),
          ]),
        ),
        const SizedBox(height:10),
        Row(children:[
          const Icon(Icons.receipt_long_outlined,size:16,color:muted),const SizedBox(width:5),
          Expanded(child:Text(items.length.toString()+' أصناف • أجرة التوصيل '+fee.toStringAsFixed(0)+' ج.م',style:const TextStyle(color:muted,fontSize:11))),
          Text((o['notes']??'').toString(),style:const TextStyle(color:muted,fontSize:10)),
        ]),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:OutlinedButton.icon(onPressed:()=>showCourierOrderDetails(context,o),icon:const Icon(Icons.receipt_long_outlined,size:18),label:const Text('التفاصيل'))),
          const SizedBox(width:8),
          Expanded(child:OutlinedButton.icon(onPressed:()=>rejectOrder(o),icon:const Icon(Icons.close_rounded,size:18),label:const Text('رفض'))),
          const SizedBox(width:8),
          Expanded(child:FilledButton.icon(onPressed:actionBusy?null:()=>acceptOrder(o),style:FilledButton.styleFrom(backgroundColor:orange),icon:const Icon(Icons.check_rounded,size:18),label:const Text('قبول'))),
        ]),
      ]),
    );
  }

  Widget earnings()=>ListView(padding:const EdgeInsets.all(18),children:[
    const Text('الأرباح',style:TextStyle(fontSize:29,fontWeight:FontWeight.w900)),const SizedBox(height:14),
    metric('دخل اليوم','486 ج.م',Icons.trending_up),
    metric('طلبات اليوم','9 طلبات',Icons.local_shipping),
    metric('الرصيد','1,840 ج.م',Icons.account_balance_wallet),
  ]);
  Widget metric(String a,String b,IconData i)=>Container(
    margin:const EdgeInsets.only(bottom:11),padding:const EdgeInsets.all(17),
    decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(20)),
    child:Row(children:[CircleAvatar(backgroundColor:orange.withValues(alpha:.1),child:Icon(i,color:orange)),const SizedBox(width:12),Text(a,style:const TextStyle(color:muted)),const Spacer(),Text(b,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900))]),
  );
  Widget account()=>ListView(padding:const EdgeInsets.all(18),children:[
    const CircleAvatar(radius:40,backgroundColor:orange,child:Icon(Icons.person,color:Colors.white,size:40)),
    const SizedBox(height:12),const Center(child:Text('مندوب نوفا',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900))),
    const SizedBox(height:15),
    ListTile(onTap:()=>snack(context,'البيانات الشخصية'),leading:const Icon(Icons.person_outline,color:orange),title:const Text('البيانات الشخصية'),trailing:const Icon(Icons.chevron_left)),
    ListTile(onTap:()=>snack(context,'المركبة والمستندات'),leading:const Icon(Icons.two_wheeler,color:orange),title:const Text('المركبة والمستندات'),trailing:const Icon(Icons.chevron_left)),
    ListTile(onTap:()=>snack(context,'الدعم'),leading:const Icon(Icons.support_agent,color:orange),title:const Text('الدعم'),trailing:const Icon(Icons.chevron_left)),
    OutlinedButton.icon(onPressed:widget.onLogout,icon:const Icon(Icons.logout),label:const Text('تسجيل الخروج')),
  ]);
}

class EmptyCourierState extends StatelessWidget{
  final IconData icon; final String title,sub;
  const EmptyCourierState({super.key,required this.icon,required this.title,required this.sub});
  @override Widget build(BuildContext c)=>Container(
    margin:const EdgeInsets.only(top:30),padding:const EdgeInsets.symmetric(vertical:35,horizontal:20),
    decoration:BoxDecoration(color:Theme.of(c).colorScheme.surface,borderRadius:BorderRadius.circular(24)),
    child:Column(children:[Icon(icon,size:60,color:orange),const SizedBox(height:12),Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:5),Text(sub,textAlign:TextAlign.center,style:const TextStyle(color:muted))]),
  );
}

String _shortId(dynamic id){
  final s=id?.toString()??'';
  return s.length>8?s.substring(0,8):s;
}
double _money(dynamic value)=>double.tryParse(value?.toString()??'0')??0;

void showCourierOrderDetails(BuildContext c, Map<String,dynamic> order){
  final items=List<Map<String,dynamic>>.from((order['order_items'] as List?)??const[]);
  showModalBottomSheet(
    context:c,isScrollControlled:true,showDragHandle:true,
    builder:(_)=>Directionality(
      textDirection:TextDirection.rtl,
      child:Padding(
        padding:const EdgeInsets.fromLTRB(18,8,18,25),
        child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text((order['restaurant_name']??'مطعم نوفا').toString(),style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900)),
          Text('العميل: '+(order['customer_name']??'عميل نوفا').toString(),style:const TextStyle(color:muted)),
          const SizedBox(height:13),
          ...items.map((x)=>ListTile(
            dense:true,contentPadding:EdgeInsets.zero,
            leading:CircleAvatar(backgroundColor:orange.withValues(alpha:.1),child:Text((x['quantity']??1).toString(),style:const TextStyle(color:orange,fontWeight:FontWeight.w900))),
            title:Text((x['item_name']??'صنف').toString(),style:const TextStyle(fontWeight:FontWeight.w800)),
            trailing:Text(_money(x['unit_price']).toStringAsFixed(0)+' ج.م'),
          )),
          const Divider(),
          Row(children:[
            const Expanded(child:Text('إجمالي الطلب',style:TextStyle(fontWeight:FontWeight.w900))),
            Text(_money(order['total']).toStringAsFixed(0)+' ج.م',style:const TextStyle(color:orange,fontWeight:FontWeight.w900,fontSize:18)),
          ]),
          const SizedBox(height:7),
          Text('عنوان الاستلام: '+(order['pickup_address']??'غير محدد').toString(),style:const TextStyle(color:muted,fontSize:11)),
          Text('عنوان العميل: '+(order['delivery_address']??'غير محدد').toString(),style:const TextStyle(color:muted,fontSize:11)),
          if((order['notes']??'').toString().isNotEmpty) Text('ملاحظات: '+order['notes'].toString(),style:const TextStyle(color:muted,fontSize:11)),
        ]),
      ),
    ),
  );
}

class CourierRoutePage extends StatefulWidget{
  final Map<String,dynamic> order;
  const CourierRoutePage({super.key,required this.order});
  @override State<CourierRoutePage> createState()=>_CourierRoutePageState();
}

class _CourierRoutePageState extends State<CourierRoutePage>{
  int step=0; List<LatLng> route=[];
  bool pickedUp=false;
  bool delivered=false;

  LatLng get pickup=>LatLng(
    double.tryParse(widget.order['pickup_lat']?.toString()??'')??31.0440,
    double.tryParse(widget.order['pickup_lng']?.toString()??'')??31.3550,
  );
  LatLng get customer=>LatLng(double.tryParse(widget.order['customer_lat']?.toString()??'')??31.0474,double.tryParse(widget.order['customer_lng']?.toString()??'')??31.3499);
  @override void initState(){super.initState();_loadRoute();}
  Future<void> _loadRoute() async { final r=await _roadRoute(pickup,customer);if(mounted)setState(()=>route=r); }

  @override Widget build(BuildContext c){
    final target=step==0?pickup:customer;
    final shop=(widget.order['restaurant_name']??'المطعم').toString();
    final customerName=(widget.order['customer_name']??'العميل').toString();
    return Scaffold(
      appBar:AppBar(title:const Text('رحلة الطلب'),actions:[IconButton(onPressed:()=>showCourierOrderDetails(c,widget.order),icon:const Icon(Icons.receipt_long_outlined))]),
      body:Column(children:[
        Expanded(child:FlutterMap(
          options:MapOptions(initialCenter:target,initialZoom:15.2),
          children:[
            TileLayer(urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png',userAgentPackageName:'nova.delivery'),
            PolylineLayer(polylines:[Polyline(points:route.isEmpty?[pickup,customer]:route,strokeWidth:5,color:orange)]),
            MarkerLayer(markers:[
              Marker(point:pickup,width:58,height:58,child:Container(
                decoration:BoxDecoration(color:step==0?orange:ink,shape:BoxShape.circle,border:Border.all(color:Colors.white,width:3)),
                child:const Icon(Icons.restaurant,color:Colors.white),
              )),
              Marker(point:customer,width:58,height:58,child:Container(
                decoration:BoxDecoration(color:step==1?orange:ink,shape:BoxShape.circle,border:Border.all(color:Colors.white,width:3)),
                child:const Icon(Icons.person_pin_circle,color:Colors.white),
              )),
            ]),
          ],
        )),
        Container(
          padding:const EdgeInsets.fromLTRB(18,14,18,18),
          decoration:BoxDecoration(color:Theme.of(c).colorScheme.surface,borderRadius:const BorderRadius.vertical(top:Radius.circular(28)),boxShadow:const[BoxShadow(color:Color(0x22000000),blurRadius:18,offset:Offset(0,-6))]),
          child:Column(children:[
            Row(children:[
              Expanded(child:routeStep(c,0,Icons.storefront_outlined,'المطعم',shop)),
              const Padding(padding:EdgeInsets.symmetric(horizontal:7),child:Icon(Icons.arrow_back_rounded,color:muted)),
              Expanded(child:routeStep(c,1,Icons.person_pin_circle_outlined,'العميل',customerName)),
            ]),
            const SizedBox(height:12),
            Text(step==0?'اتجه للمطعم أولًا واستلم الطلب':'اتجه للعميل وسلّم الطلب',style:const TextStyle(fontWeight:FontWeight.w900)),
            const SizedBox(height:10),
            SizedBox(width:double.infinity,child:FilledButton.icon(
              onPressed:(){
                if(step==0){
                  setState(()=>pickedUp=true);
                  setState(()=>step=1);
                  snack(c,'تم تحديد الاستلام من المطعم. الآن وجهتك العميل 📍');
                }else{
                  setState(()=>delivered=true);
                  snack(c,'تم تسليم الطلب بنجاح ✅');
                }
              },
              style:FilledButton.styleFrom(backgroundColor:orange,minimumSize:const Size.fromHeight(52)),
              icon:Icon(step==0?Icons.storefront:Icons.done_all),
              label:Text(step==0?'وصلت للمطعم واستلمت الطلب':'تم التسليم للعميل'),
            )),
            const SizedBox(height:8),
            Row(children:[
              Expanded(child:OutlinedButton.icon(onPressed:()=>setState(()=>step=0),icon:const Icon(Icons.restaurant_outlined),label:const Text('المطعم'))),
              const SizedBox(width:8),
              Expanded(child:OutlinedButton.icon(onPressed:()=>setState(()=>step=1),icon:const Icon(Icons.person_pin_circle_outlined),label:const Text('العميل'))),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget routeStep(BuildContext c,int index,IconData icon,String titleText,String sub){
    final active=step==index;
    final done=index==0?pickedUp:delivered;
    return InkWell(
      onTap:()=>setState(()=>step=index),
      borderRadius:BorderRadius.circular(16),
      child:Container(
        padding:const EdgeInsets.all(10),
        decoration:BoxDecoration(color:active?orange.withValues(alpha:.10):Colors.transparent,borderRadius:BorderRadius.circular(16),border:Border.all(color:active?orange.withValues(alpha:.35):Colors.transparent)),
        child:Row(children:[
          CircleAvatar(radius:19,backgroundColor:done?Colors.green:active?orange:ink,child:Icon(done?Icons.check:icon,color:Colors.white,size:18)),
          const SizedBox(width:8),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(titleText,style:TextStyle(color:active?orange:null,fontWeight:FontWeight.w900,fontSize:12)),
            Text(sub,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:muted,fontSize:9)),
          ])),
        ]),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState()=>_ShellState();
}
class _ShellState extends State<Shell> {
  int tab=0; final cart=<Line>[]; final fav=<String>{};
  double get total=>cart.fold(0,(s,x)=>s+x.m.price*x.qty);
  int get count=>cart.fold(0,(s,x)=>s+x.qty);
  Future<void> add(R r,M m) async {
    final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(24)),
      title:const Text('إضافة للسلة',style:TextStyle(fontWeight:FontWeight.w900)),
      content:Row(children:[ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.network(m.image,width:72,height:72,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(width:72,height:72,color:const Color(0xFFF1F1F2),child:const Icon(Icons.fastfood_rounded,color:orange)))),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[Text(m.name,style:const TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:5),Text(r.name,style:const TextStyle(color:muted,fontSize:11)),const SizedBox(height:5),Text(m.price.toStringAsFixed(0)+' ج.م',style:const TextStyle(color:orange,fontWeight:FontWeight.w900))]))]),
      actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton.icon(onPressed:()=>Navigator.pop(d,true),icon:const Icon(Icons.add_shopping_cart_rounded),label:const Text('أضف للسلة'))],
    ));
    if(ok!=true||!mounted)return;
    setState((){final i=cart.indexWhere((x)=>x.r.name==r.name&&x.m.name==m.name);if(i>=0){cart[i].qty++;}else{cart.add(Line(r,m));}});
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تمت إضافة المنتج للسلة ✓'),duration:Duration(milliseconds:900)));
  }
  void sub(Line x)=>setState((){if(x.qty>1){x.qty--;}else{cart.remove(x);}});
  void open(R r)=>Navigator.push(context,MaterialPageRoute(builder:(_)=>RestaurantPage(r:r,fav:favoriteRestaurants.contains(r.name),onFav:()=>setState((){if(!favoriteRestaurants.add(r.name))favoriteRestaurants.remove(r.name);}),onAdd:add)));
  @override Widget build(BuildContext context){
    final pages=[
      Home(onOpen:open,onMap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MapPage())),onSearch:(q)=>setState(()=>tab=1),onAdd:add),
      SearchPage(onAdd:add,onFav:(r)=>setState((){if(!favoriteRestaurants.add(r.name))favoriteRestaurants.remove(r.name);}),),
      OrdersPage(onTrack:(o)=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CustomerOrderTrackingPage(order:o))),),
      ProfilePage(onMap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MapPage())),onLogout:()=>NovaSupabase.signOut()),
    ];
    return Directionality(
      textDirection:TextDirection.rtl,
      child:LayoutBuilder(
        builder:(context,box){
          final wide=box.maxWidth>=900;
          final content=Center(
            child:ConstrainedBox(
              constraints:const BoxConstraints(maxWidth:1240),
              child:IndexedStack(index:tab,children:pages),
            ),
          );
          if(!wide){
            return Scaffold(
              body:SafeArea(child:content),
              bottomNavigationBar:NavigationBar(
                selectedIndex:tab,
                onDestinationSelected:(v)=>setState(()=>tab=v),
                destinations:const[
                  NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded),label:'الرئيسية'),
                  NavigationDestination(icon:Icon(Icons.search_rounded),label:'اكتشف'),
                  NavigationDestination(icon:Icon(Icons.receipt_long_outlined),label:'طلباتي'),
                  NavigationDestination(icon:Icon(Icons.person_outline),label:'حسابي'),
                ],
              ),
              floatingActionButton:count==0?null:FloatingActionButton(
                backgroundColor:orange,foregroundColor:Colors.white,elevation:12,
                onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CartPage(cart:cart,total:total,onAdd:(x)=>add(x.r,x.m),onSub:sub,onCheckoutSuccess:()=>setState(cart.clear)))),
                child:Stack(clipBehavior:Clip.none,children:[
                  const Icon(Icons.shopping_cart_rounded,size:28),
                  Positioned(right:-8,top:-9,child:Container(constraints:const BoxConstraints(minWidth:22,minHeight:22),padding:const EdgeInsets.symmetric(horizontal:5),alignment:Alignment.center,decoration:const BoxDecoration(color:ink,shape:BoxShape.circle),child:Text(count.toString(),style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w900)))),
                ]),
              ),
            );
          }
          return Scaffold(
            body:SafeArea(
              child:Row(children:[
                Container(
                  width:92,
                  decoration:BoxDecoration(
                    color:Theme.of(context).colorScheme.surface,
                    border:Border(left:BorderSide(color:Theme.of(context).dividerColor.withValues(alpha:.35))),
                  ),
                  child:NavigationRail(
                    selectedIndex:tab,
                    onDestinationSelected:(v)=>setState(()=>tab=v),
                    labelType:NavigationRailLabelType.all,
                    leading:Padding(
                      padding:const EdgeInsets.only(top:10,bottom:18),
                      child:Container(
                        width:48,height:48,
                        decoration:BoxDecoration(color:orange,borderRadius:BorderRadius.circular(15)),
                        child:const Icon(Icons.delivery_dining_rounded,color:Colors.white,size:29),
                      ),
                    ),
                    destinations:const[
                      NavigationRailDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded),label:Text('الرئيسية')),
                      NavigationRailDestination(icon:Icon(Icons.search_rounded),label:Text('اكتشف')),
                      NavigationRailDestination(icon:Icon(Icons.receipt_long_outlined),label:Text('طلباتي')),
                      NavigationRailDestination(icon:Icon(Icons.person_outline),label:Text('حسابي')),
                    ],
                  ),
                ),
                Expanded(child:content),
              ]),
            ),
            floatingActionButton:count==0?null:FloatingActionButton.extended(
              backgroundColor:orange,foregroundColor:Colors.white,
              onPressed:()=>setState(()=>tab=3),
              icon:const Icon(Icons.shopping_bag_outlined),
              label:Text(count.toString()+' • '+total.toStringAsFixed(0)+' ج.م'),
            ),
          );
        },
      ),
    );
  }
}

class Home extends StatefulWidget {
  final ValueChanged<R> onOpen; final VoidCallback onMap; final ValueChanged<String> onSearch; final void Function(R,M) onAdd;
  const Home({super.key,required this.onOpen,required this.onMap,required this.onSearch,required this.onAdd});
  @override State<Home> createState()=>_HomeState();
}
class _HomeState extends State<Home>{
  String deliveryAddress='جاري تحديد عنوان التوصيل…';
  @override void initState(){super.initState();_loadAddress();}
  Future<void> _loadAddress() async {
    try{
      final rows=await NovaSupabase.addresses();
      if(!mounted)return;
      setState(()=>deliveryAddress=rows.isEmpty?'اختر عنوانك من الخريطة':(rows.first['address']??'اختر عنوانك من الخريطة').toString());
    }catch(_){if(mounted)setState(()=>deliveryAddress='اختر عنوانك من الخريطة');}
  }
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(18,10,18,110),children:[
    Row(children:[
      Expanded(child:Center(child:RichText(text:TextSpan(children:[
        TextSpan(text:'نوفا ',style:TextStyle(color:ink,fontSize:25,fontWeight:FontWeight.w900)),
        TextSpan(text:'ديليفري',style:TextStyle(color:orange,fontSize:25,fontWeight:FontWeight.w900)),
      ])))),
      IconButton.filledTonal(onPressed:()=>showNotifications(context),icon:const Icon(Icons.notifications_none_rounded,color:ink)),
    ]),
    const SizedBox(height:16),
    InkWell(onTap:widget.onMap,borderRadius:BorderRadius.circular(18),child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(18)),child:Row(children:[const Icon(Icons.location_on_rounded,color:orange),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('عنوان التوصيل',style:TextStyle(color:muted,fontSize:10)),FutureBuilder<String>(future:resolveCurrentAddress(),builder:(c,s){return Text(s.data??'جاري تحديد عنوانك الحالي…',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold));})])),const Icon(Icons.chevron_left_rounded)]))),
    const SizedBox(height:18),
    Container(
      height:210,
      decoration:BoxDecoration(color:ink,borderRadius:BorderRadius.circular(28),boxShadow:const[BoxShadow(color:Color(0x33000000),blurRadius:22,offset:Offset(0,10))]),
      child:ClipRRect(
        borderRadius:BorderRadius.circular(28),
        child:Stack(fit:StackFit.expand,children:[
          Image.asset('assets/nova_rider.webp',fit:BoxFit.cover),
          const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0x22000000),Color(0xD9000000)]))),
          const Positioned(right:18,top:18,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('كل اللي نفسك فيه…',style:TextStyle(color:Colors.white70)),
            SizedBox(height:4),
            Text('يوصل لبابك بسرعة 🚀',style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w900)),
          ])),
          Positioned(bottom:14,left:14,child:FilledButton(onPressed:widget.onMap,style:FilledButton.styleFrom(backgroundColor:orange,foregroundColor:Colors.white),child:const Text('افتح الخريطة'))),
        ]),
      ),
    ),
    const SizedBox(height:23),title(appCopy['mood_title']??'اختار إللي على مزاجك','عرض الكل'),const SizedBox(height:11),
    SizedBox(height:112,child:ListView(scrollDirection:Axis.horizontal,children:[Cat(Icons.lunch_dining_rounded,'برجر',onAdd:widget.onAdd),Cat(Icons.restaurant_rounded,'فراخ',onAdd:widget.onAdd),Cat(Icons.local_pizza_rounded,'بيتزا',onAdd:widget.onAdd),Cat(Icons.cake_rounded,'حلويات',onAdd:widget.onAdd),Cat(Icons.local_drink_rounded,'مشروبات',onAdd:widget.onAdd),Cat(Icons.spa_rounded,'صحي',onAdd:widget.onAdd),Cat(Icons.coffee_rounded,'قهوة',onAdd:widget.onAdd),Cat(Icons.breakfast_dining_rounded,'فطار',onAdd:widget.onAdd)])),
    const SizedBox(height:20),
    const Text('عروض معمولة ليك',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),
    const SizedBox(height:11),
    FutureBuilder<List<Map<String,dynamic>>>(
      future:NovaSupabase.activeOffers(),
      builder:(c,snap){
        final offers=snap.data??const <Map<String,dynamic>>[];
        if(offers.isEmpty)return const SizedBox(height:122,child:Center(child:Text('لا توجد عروض منشورة حالياً',style:TextStyle(color:muted))));
        return SizedBox(height:150,child:ListView(
          scrollDirection:Axis.horizontal,
          children:offers.map((o)=>_LivePromoCard(offer:o)).toList(),
        ));
      },
    ),
    const SizedBox(height:22),title('مطاعم حقيقية حولك','الخريطة'),const SizedBox(height:12),
    ...data.map((r)=>Padding(padding:const EdgeInsets.only(bottom:14),child:CardR(r:r,onTap:()=>widget.onOpen(r)))),
    const SizedBox(height:4),const Text('المصادر: المنيوز و EGMenus • تحقق من البيانات: سبتمبر 2026',style:TextStyle(color:muted,fontSize:10)),
  ]);
}

Widget title(String a,String b)=>Row(children:[Expanded(child:Text(a,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900))),Text(b,style:const TextStyle(color:orange,fontSize:12,fontWeight:FontWeight.bold))]);

class Cat extends StatelessWidget {
  final IconData icon; final String n; final void Function(R,M) onAdd; const Cat(this.icon,this.n,{super.key,required this.onAdd});
  @override Widget build(BuildContext c)=>Material(color:Colors.transparent,child:InkWell(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>CategoryPage(title:n,category:n,onAdd:onAdd))),borderRadius:BorderRadius.circular(22),child:Container(width:104,margin:const EdgeInsets.only(left:10),padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFEDEDEF)),boxShadow:const[BoxShadow(color:Color(0x0A000000),blurRadius:18,offset:Offset(0,7))]),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Container(width:48,height:48,decoration:BoxDecoration(color:orange.withValues(alpha:.10),shape:BoxShape.circle),child:Icon(icon,color:orange,size:25)),const SizedBox(height:7),Text(n,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:12))]))));
}


class _LivePromoCard extends StatelessWidget{
  final Map<String,dynamic> offer;
  const _LivePromoCard({required this.offer});

  void openTarget(BuildContext c) {
    final type=(offer['target_type']??'coupon').toString();
    final value=(offer['target_value']??'').toString().trim();
    if(type=='restaurant' && value.isNotEmpty){
      final hits=data.where((r)=>r.name.trim()==value).toList();
      if(hits.isNotEmpty){
        Navigator.push(c,MaterialPageRoute(builder:(_)=>RestaurantPage(r:hits.first,fav:false,onFav:(){},onAdd:(r,m)=>snack(c,'أضف الصنف للسلة من صفحة المطعم.'))));
        return;
      }
    }
    if(type=='category' && value.isNotEmpty){
      Navigator.push(c,MaterialPageRoute(builder:(_)=>CategoryPage(title:value,category:value,onAdd:(r,m)=>snack(c,'أضف الصنف للسلة من صفحة المطعم.'))));
      return;
    }
    if(type=='map'){Navigator.push(c,MaterialPageRoute(builder:(_)=>const MapPage()));return;}
    if(type=='home'){Navigator.popUntil(c,(route)=>route.isFirst);return;}
    final coupon=offer['coupons'] is Map?Map<String,dynamic>.from(offer['coupons'] as Map):null;
    final code=coupon?['code']?.toString();
    showDialog(context:c,builder:(_)=>AlertDialog(
      title:Text((offer['title']??'عرض نوفا').toString()),
      content:Text(code==null?(offer['subtitle']??'').toString():'كود العرض: '+code+'\n\n'+(offer['subtitle']??'').toString()),
      actions:[
        if(code!=null)TextButton(onPressed:(){Clipboard.setData(ClipboardData(text:code));Navigator.pop(c);snack(c,'تم نسخ الكود '+code);},child:const Text('نسخ')),
        TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إغلاق')),
      ],
    ));
  }

  @override Widget build(BuildContext c){
    final image=offer['image_url']?.toString()??'';
    return InkWell(
      onTap:()=>openTarget(c),
      borderRadius:BorderRadius.circular(22),
      child:Container(
        width:255,margin:const EdgeInsets.only(left:10),clipBehavior:Clip.antiAlias,
        decoration:BoxDecoration(color:ink,borderRadius:BorderRadius.circular(22),boxShadow:const[BoxShadow(color:Color(0x18000000),blurRadius:18,offset:Offset(0,7))]),
        child:Stack(fit:StackFit.expand,children:[
          if(image.isNotEmpty)Image.network(image,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox()),
          const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0x11000000),Color(0xE6000000)]))),
          Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.end,children:[
            Text((offer['title']??'عرض نوفا').toString(),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:17)),
            const SizedBox(height:3),Text((offer['subtitle']??'').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white70,fontSize:10)),
            Padding(padding:const EdgeInsets.only(top:7),child:Text((offer['target_label']??offer['target_type']??'عرض').toString(),style:const TextStyle(color:orange,fontWeight:FontWeight.w900,fontSize:10))),
          ])),
        ]),
      ),
    );
  }
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
      const SizedBox(height:6),Row(children:[const Icon(Icons.restaurant_menu,size:15,color:muted),const SizedBox(width:5),Text(r.type,style:const TextStyle(color:muted,fontSize:11)),const Spacer(),const Icon(Icons.access_time,size:15,color:muted),const SizedBox(width:4),Text('25–40 دقيقة',style:const TextStyle(color:muted,fontSize:11))]),
      const SizedBox(height:7),Row(children:[const Icon(Icons.location_on_outlined,size:15,color:orange),const SizedBox(width:4),Expanded(child:Text(r.address,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:muted,fontSize:10)))]),
    ])),
  ])));
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
class _SearchPageState extends State<SearchPage> {
  late String q;
  @override void initState(){super.initState();q=widget.initialQuery;}
  @override
  Widget build(BuildContext c) {
    final list = data.where((r) => q.isEmpty || r.name.contains(q) || r.type.contains(q)).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      children: [
        const Text('اكتشف', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('مطاعم ومنيوهات حقيقية حولك', style: TextStyle(color: muted)),
        const SizedBox(height: 18),
        TextField(
          onChanged: (v) => setState(() => q = v),
          decoration: InputDecoration(
            hintText: 'ابحث باسم المطعم أو النوع…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: const Icon(Icons.tune_rounded),
            filled: true,
            fillColor: Theme.of(c).colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 18),
        ...list.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: CardR(
            r: r,
            onTap: () => Navigator.push(c, MaterialPageRoute(
              builder: (_) => RestaurantPage(r: r, fav: false, onFav: ()=>widget.onFav(r), onAdd: widget.onAdd),
            )),
          ),
        )),
      ],
    );
  }
}
class SearchPage extends StatefulWidget{final void Function(R,M) onAdd; final ValueChanged<R> onFav; final String initialQuery;
  const SearchPage({super.key,required this.onAdd,required this.onFav,this.initialQuery='' }); @override State<SearchPage> createState()=>_SearchPageState();}
class OTile extends StatelessWidget {
  final String id, shop, status;
  final bool active;
  const OTile(this.id, this.shop, this.status, this.active, {super.key});
  @override
  Widget build(BuildContext c) {
    final col = active ? orange : Colors.green;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Theme.of(c).colorScheme.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Row(children: [
          CircleAvatar(backgroundColor: col.withValues(alpha: .12), child: Icon(active ? Icons.delivery_dining : Icons.check, color: col)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(shop, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text('#' + id, style: const TextStyle(color: muted, fontSize: 11)),
          ])),
          Icon(active ? Icons.location_on : Icons.check_circle, color: col),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Icon(active ? Icons.bolt : Icons.done_all, color: col, size: 18),
          const SizedBox(width: 7),
          Text(status, style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 12)),
        ]),
        if (active) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(value: .72, color: orange, minHeight: 7),
          const SizedBox(height: 8),
          const Align(alignment: Alignment.centerRight, child: Text('متوقع الوصول خلال 18 دقيقة', style: TextStyle(color: muted, fontSize: 11))),
        ],
      ]),
    );
  }
}
class OrdersPage extends StatefulWidget{
  final ValueChanged<Map<String,dynamic>> onTrack;
  const OrdersPage({super.key,required this.onTrack});
  @override State<OrdersPage> createState()=>_OrdersPageState();
}
class _OrdersPageState extends State<OrdersPage>{
  int tab=0;
  bool loading=true;
  List<Map<String,dynamic>> orders=[];
  dynamic channel;
  @override void initState(){super.initState();load();}
  @override void dispose(){channel?.unsubscribe();super.dispose();}
  Future<void> load() async{
    if(!NovaSupabase.initialized || NovaSupabase.currentUser==null){
      if(mounted)setState(()=>loading=false);
      return;
    }
    try{
      final rows=await NovaSupabase.customerOrders();
      if(!mounted)return;
      setState(()=>orders=rows);
      channel ??=NovaSupabase.watchCustomerOrders(load);
    }catch(e){if(mounted)snack(context,'تعذر تحميل الطلبات: $e');}
    finally{if(mounted)setState(()=>loading=false);}
  }
  String statusText(String s)=>switch(s){
    'pending'=>'في انتظار المطعم','accepted'=>'المطعم قبل الطلب','preparing'=>'جاري التحضير','ready'=>'جاهز للاستلام','picked_up'=>'تم الاستلام','on_the_way'=>'السائق في الطريق','delivered'=>'تم التسليم','cancelled'=>'تم الإلغاء',_=>s
  };
  @override Widget build(BuildContext c){
    final current=orders.where((o)=>!['delivered','cancelled'].contains(o['status'])).toList();
    final history=orders.where((o)=>['delivered','cancelled'].contains(o['status'])).toList();
    final list=tab==0?current:history;
    return RefreshIndicator(onRefresh:load,child:ListView(
      physics:const AlwaysScrollableScrollPhysics(),
      padding:const EdgeInsets.fromLTRB(18,18,18,110),
      children:[
        const Text('طلباتي',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900)),
        const SizedBox(height:5),const Text('كل طلباتك في مكان واحد',style:TextStyle(color:muted)),
        const SizedBox(height:18),
        Container(padding:const EdgeInsets.all(5),decoration:BoxDecoration(color:Theme.of(c).colorScheme.surface,borderRadius:BorderRadius.circular(17)),child:Row(children:[
          Expanded(child:InkWell(onTap:()=>setState(()=>tab=0),child:Center(child:Padding(padding:const EdgeInsets.all(10),child:Text('الحالية',style:TextStyle(color:tab==0?orange:muted,fontWeight:FontWeight.w900)))))),
          Expanded(child:InkWell(onTap:()=>setState(()=>tab=1),child:Center(child:Padding(padding:const EdgeInsets.all(10),child:Text('السابقة',style:TextStyle(color:tab==1?orange:muted,fontWeight:FontWeight.w900)))))),
        ])),
        const SizedBox(height:15),
        if(loading)const Padding(padding:EdgeInsets.all(35),child:Center(child:CircularProgressIndicator(color:orange)))
        else if(list.isEmpty)Container(padding:const EdgeInsets.all(28),decoration:BoxDecoration(color:Theme.of(c).colorScheme.surface,borderRadius:BorderRadius.circular(22)),child:const Column(children:[Icon(Icons.receipt_long_outlined,size:58,color:orange),SizedBox(height:10),Text('لا توجد طلبات هنا',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),SizedBox(height:5),Text('طلباتك الجديدة ستظهر هنا تلقائياً',style:TextStyle(color:muted))]))
         else ...[for (final o in list) orderTile(c, o, statusText(o['status']?.toString() ?? ''))],
      ],
    ));
  }
  Widget orderTile(BuildContext c,Map<String,dynamic> o,String status){
    final active=!['delivered','cancelled'].contains(o['status']);
    return InkWell(onTap:()=>widget.onTrack(o),borderRadius:BorderRadius.circular(22),child:Container(
      margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(16),
      decoration:BoxDecoration(color:Theme.of(c).colorScheme.surface,borderRadius:BorderRadius.circular(22),border:Border.all(color:active?orange.withValues(alpha:.18):Colors.transparent)),
      child:Row(children:[
        CircleAvatar(backgroundColor:(active?orange:Colors.green).withValues(alpha:.12),child:Icon(active?Icons.delivery_dining:Icons.check_circle,color:active?orange:Colors.green)),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text((o['restaurant_name']??'مطعم نوفا').toString(),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),
          Text('#'+_shortId(o['id']),style:const TextStyle(color:muted,fontSize:10)),
          const SizedBox(height:4),Text(status,style:TextStyle(color:active?orange:Colors.green,fontWeight:FontWeight.w800,fontSize:11)),
        ])),
        Text(_money(o['total']).toStringAsFixed(0)+' ج.م',style:const TextStyle(fontWeight:FontWeight.w900)),
        const SizedBox(width:4),const Icon(Icons.chevron_left_rounded,color:muted),
      ]),
    ));
  }
}

class CartPage extends StatelessWidget {
  final List<Line> cart;
  final double total;
  final void Function(Line) onAdd, onSub; final VoidCallback onCheckoutSuccess;
  const CartPage({super.key, required this.cart, required this.total, required this.onAdd, required this.onSub, required this.onCheckoutSuccess});
  @override
  Widget build(BuildContext c) {
    if (cart.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.shopping_bag_outlined, size: 80, color: orange),
        SizedBox(height: 15),
        Text('السلة لسه فاضية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        Text('اختار أكلك المفضل وابدأ طلبك', style: TextStyle(color: muted)),
      ]));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      children: [
        const Text('السلة', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        ...cart.map((x) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Theme.of(c).colorScheme.surface, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(x.m.image, width: 72, height: 72, fit: BoxFit.cover)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(x.m.name, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(x.r.name, style: const TextStyle(color: muted, fontSize: 11)),
              Text((x.m.price * x.qty).toStringAsFixed(0) + ' ج.م', style: const TextStyle(color: orange, fontWeight: FontWeight.w900)),
            ])),
            Row(children: [
              IconButton(onPressed: () => onSub(x), icon: const Icon(Icons.remove_circle_outline)),
              Text(x.qty.toString()),
              IconButton(onPressed: () => onAdd(x), icon: const Icon(Icons.add_circle_outline, color: orange)),
            ]),
          ]),
        )),
        line('المجموع', total),
        line('التوصيل', 25),
        line('الخدمة', 8),
        const Divider(height: 28),
        line('الإجمالي', total + 33, bold: true),
        const SizedBox(height: 14),
        FilledButton(onPressed: () => checkout(c, cart, total + 33, onCheckoutSuccess), style: FilledButton.styleFrom(backgroundColor: orange, minimumSize: const Size.fromHeight(55)), child: const Text('إتمام الطلب')),
      ],
    );
  }
}

void snack(BuildContext c,String message){
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(message)));
}

Widget line(String s,double v,{bool bold=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Expanded(child:Text(s,style:TextStyle(fontWeight:bold?FontWeight.w900:FontWeight.w500))),Text(v.toStringAsFixed(0)+' ج.م',style:TextStyle(fontWeight:FontWeight.w900,color:bold?orange:null))]));

class ProfilePage extends StatefulWidget{
  final VoidCallback onMap,onLogout;
  const ProfilePage({super.key,required this.onMap,required this.onLogout});
  @override State<ProfilePage> createState()=>_ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage>{
  Map<String,dynamic>? profile;String? role;
  @override void initState(){super.initState();load();}
  Future<void> load()async{try{profile=await NovaSupabase.profile();role=await NovaSupabase.currentUserRole();}catch(_){ }if(mounted)setState((){});}
  Future<void> editProfile()async{
    final name=TextEditingController(text:(profile?['full_name']??'').toString());
    String? pickedAvatar;
    await showDialog(context:context,builder:(d)=>StatefulBuilder(builder:(d,setDialogState)=>AlertDialog(
      title:const Text('تعديل الملف الشخصي'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        GestureDetector(
          onTap:()async{
            final file=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:90,maxWidth:1400);
            if(file==null)return;
            try{
              final user=NovaSupabase.currentUser;
              if(user==null)throw const AuthException('يجب تسجيل الدخول أولاً.');
              pickedAvatar=await NovaSupabase.uploadAvatar(user.id,await file.readAsBytes());
              setDialogState((){});
            }catch(e){if(d.mounted)snack(d,'تعذر رفع الصورة: '+e.toString());}
          },
          child:CircleAvatar(
            radius:42,
            backgroundColor:orange.withValues(alpha:.12),
            backgroundImage:pickedAvatar!=null?NetworkImage(pickedAvatar!):((profile?['avatar_url']??'').toString().isEmpty?null:NetworkImage(profile!['avatar_url'].toString())),
            child:(pickedAvatar==null&&(profile?['avatar_url']??'').toString().isEmpty)?const Icon(Icons.add_a_photo_rounded,color:orange,size:30):null,
          ),
        ),
        const SizedBox(height:9),
        const Text('اضغط على الصورة لاختيار صورة بروفايل',style:TextStyle(color:muted,fontSize:11)),
        const SizedBox(height:14),
        TextField(controller:name,decoration:const InputDecoration(labelText:'اسمك الظاهر في التطبيق',prefixIcon:Icon(Icons.person_outline))),
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(d),child:const Text('إلغاء')),
        FilledButton(onPressed:()async{
          try{
            await NovaSupabase.updateProfile(fullName:name.text.trim(),avatarUrl:pickedAvatar);
            if(d.mounted)Navigator.pop(d);
            await load();
          }catch(e){if(d.mounted)snack(d,'تعذر الحفظ: '+e.toString());}
        },child:const Text('حفظ')),
      ],
    )));
    name.dispose();
  }
  Future<void> changeAvatar()async{try{final file=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:88,maxWidth:1200);if(file==null)return;final url=await NovaSupabase.uploadAvatar(NovaSupabase.currentUser!.id,await file.readAsBytes());await NovaSupabase.updateProfile(avatarUrl:url);await load();}catch(e){if(mounted)snack(context,'تعذر تحديث الصورة: '+e.toString());}}
  Future<void> logout()async{
    final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:const Text('تأكيد تسجيل الخروج'),content:const Text('هل تريد تسجيل الخروج من حسابك؟'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('تسجيل الخروج'))]));
    if(ok==true){try{await NovaSupabase.signOut();widget.onLogout();}catch(e){if(mounted)snack(context,'تعذر تسجيل الخروج: '+e.toString());}}
  }
  @override Widget build(BuildContext c){
    final owner=role=='admin';
    return ListView(padding:const EdgeInsets.fromLTRB(18,18,18,110),children:[
      const Text('حسابي',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900)),
      const SizedBox(height:5),
      const Text('إدارة حسابك وطلباتك ومساعدتك في مكان واحد',style:TextStyle(color:muted)),
      const SizedBox(height:18),
      Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:ink,borderRadius:BorderRadius.circular(26)),child:Row(children:[
        Container(width:48,height:48,decoration:BoxDecoration(color:orange,borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.person_outline_rounded,color:Colors.white)),
        const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(owner?'وضع المالك':'وضع العميل',style:const TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.w900)),
          const SizedBox(height:3),Text(owner?'لديك وصول كامل لمركز التحكم':'كل خدمات نوفا متاحة من هنا',style:const TextStyle(color:Colors.white70,fontSize:11)),
        ])),
      ])),
      const SizedBox(height:18),
      st(c,Icons.location_on_outlined,'العناوين والخريطة','موقعك الحالي والأماكن القريبة',widget.onMap),
      st(c,Icons.favorite_border_rounded,'المفضلة',favoriteRestaurants.isEmpty?'لم تحفظ أي مطعم بعد':'${favoriteRestaurants.length} مطعم محفوظ',()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const FavoritesPage()))),
      st(c,Icons.support_agent_rounded,'مركز المساعدة','تحدث مع Nova AI أو اطلب مسؤولاً',()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const SupportCenterPage()))),
      if(owner) st(c,Icons.dashboard_customize_rounded,'لوحة نوفا','الطلبات والمطاعم والمنيو والعروض والدعم والمحتوى',()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const OwnerDashboardPage()))),
      st(c,Icons.logout_rounded,'تسجيل الخروج','الخروج من الحساب على هذا الجهاز',logout),
    ]);
  }
}
Future<List<LatLng>> _roadRoute(LatLng from,LatLng to) async {
  try{
    final uri=Uri.parse('https://router.project-osrm.org/route/v1/driving/'+from.longitude.toString()+','+from.latitude.toString()+';'+to.longitude.toString()+','+to.latitude.toString()+'?overview=full&geometries=geojson');
    final response=await http.get(uri,headers:{'User-Agent':'NovaDelivery/2.1'});
    if(response.statusCode!=200)return [from,to];
    final body=Map<String,dynamic>.from(jsonDecode(response.body) as Map);
    final routes=body['routes'] as List?;
    if(routes==null||routes.isEmpty)return [from,to];
    final geometry=Map<String,dynamic>.from(routes.first['geometry'] as Map);
    final coords=geometry['coordinates'] as List;
    return coords.map((p)=>LatLng((p[1] as num).toDouble(),(p[0] as num).toDouble())).toList();
  }catch(_){return [from,to];}
}

class CustomerOrderTrackingPage extends StatefulWidget{
  final Map<String,dynamic> order;
  const CustomerOrderTrackingPage({super.key,required this.order});
  @override State<CustomerOrderTrackingPage> createState()=>_CustomerOrderTrackingPageState();
}
class _CustomerOrderTrackingPageState extends State<CustomerOrderTrackingPage>{
  dynamic channel;
  List<LatLng> route=[];
  Map<String,dynamic> current;
  _CustomerOrderTrackingPageState():current={};
  @override void initState(){super.initState();current=Map<String,dynamic>.from(widget.order);_watch();_loadRoute();}
  Future<void> _loadRoute() async { final lat=double.tryParse(current['customer_lat']?.toString()??''); final lng=double.tryParse(current['customer_lng']?.toString()??''); final clat=double.tryParse(current['courier_lat']?.toString()??''); final clng=double.tryParse(current['courier_lng']?.toString()??''); if(lat==null||lng==null||clat==null||clng==null)return; final r=await _roadRoute(LatLng(clat,clng),LatLng(lat,lng)); if(mounted)setState(()=>route=r); }
  void _watch(){
    if(!NovaSupabase.initialized||NovaSupabase.currentUser==null)return;
    channel=NovaSupabase.watchCustomerOrders(() async {
      try{
        final rows=await NovaSupabase.customerOrders();
        final id=widget.order['id'].toString();
        final hit=rows.where((x)=>x['id'].toString()==id).toList();
        if(hit.isNotEmpty&&mounted){setState(()=>current=hit.first);await _loadRoute();}
      }catch(_){}
    });
  }
  @override void dispose(){channel?.unsubscribe();super.dispose();}
  @override Widget build(BuildContext c){
    final lat=double.tryParse(current['customer_lat']?.toString()??'')??31.0445;
    final lng=double.tryParse(current['customer_lng']?.toString()??'')??31.3540;
    final clat=double.tryParse(current['courier_lat']?.toString()??'')??lat;
    final clng=double.tryParse(current['courier_lng']?.toString()??'')??lng;
    final hasCourier=current['courier_lat']!=null&&current['courier_lng']!=null;
    final status=(current['status']??'pending').toString();
    final steps=['pending','accepted','preparing','ready','picked_up','on_the_way','delivered'];
    final idx=steps.indexOf(status);
    return Scaffold(
      appBar:AppBar(title:const Text('تتبع الطلب'),actions:[IconButton(onPressed:() async {try{final rows=await NovaSupabase.customerOrders();final id=widget.order['id'].toString();final hit=rows.where((x)=>x['id'].toString()==id).toList();if(hit.isNotEmpty&&mounted)setState(()=>current=hit.first);}catch(e){if(mounted)snack(c,'تعذر التحديث: $e');}},icon:const Icon(Icons.refresh_rounded))]),
      body:Column(children:[
        Expanded(child:FlutterMap(
          options:MapOptions(initialCenter:LatLng(hasCourier?clat:lat,hasCourier?clng:lng),initialZoom:14.8),
          children:[
            TileLayer(urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png',userAgentPackageName:'com.nova.delivery'),
            if(hasCourier)PolylineLayer(polylines:[Polyline(points:route.isEmpty?[LatLng(clat,clng),LatLng(lat,lng)]:route,strokeWidth:5,color:orange)]),
            MarkerLayer(markers:[
              Marker(point:LatLng(lat,lng),width:55,height:55,child:Container(decoration:BoxDecoration(color:orange,shape:BoxShape.circle,border:Border.all(color:Colors.white,width:3)),child:const Icon(Icons.home_rounded,color:Colors.white))),
              if(hasCourier)Marker(point:LatLng(clat,clng),width:55,height:55,child:Container(decoration:BoxDecoration(color:ink,shape:BoxShape.circle,border:Border.all(color:Colors.white,width:3)),child:const Icon(Icons.delivery_dining_rounded,color:Colors.white))),
            ]),
          ],
        )),
        Container(
          padding:const EdgeInsets.fromLTRB(18,15,18,20),
          decoration:BoxDecoration(color:Theme.of(c).colorScheme.surface,borderRadius:const BorderRadius.vertical(top:Radius.circular(28))),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text((current['restaurant_name']??'مطعم نوفا').toString(),style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),
            Text('#'+_shortId(current['id']),style:const TextStyle(color:muted,fontSize:10)),
            const SizedBox(height:12),
            Text(status=='delivered'?'تم التسليم بنجاح 🎉':status=='on_the_way'?'السائق في الطريق إليك 🚴':status=='pending'?'في انتظار قبول الطلب':'جاري تجهيز طلبك',style:const TextStyle(fontWeight:FontWeight.w900)),
            const SizedBox(height:10),
            Row(children:List.generate(steps.length,(i)=>Expanded(child:Container(height:7,margin:const EdgeInsets.symmetric(horizontal:2),decoration:BoxDecoration(color:i<=idx?orange:Colors.black12,borderRadius:BorderRadius.circular(8)))))),
            const SizedBox(height:12),
            Text((current['delivery_address']??'عنوان التوصيل').toString(),style:const TextStyle(color:muted,fontSize:11)),
          ]),
        ),
      ]),
    );
  }
}

class MapPage extends StatefulWidget {
  final R? restaurant;
  const MapPage({super.key,this.restaurant});
  @override State<MapPage> createState()=>_MapPageState();
}

class _MapPageState extends State<MapPage>{
  final MapController mapController=MapController();
  final TextEditingController searchController=TextEditingController();
  LatLng? me;
  String currentAddress='جاري تحديد عنوانك الحالي…';
  String? locationError;
  bool locating=true,searching=false;
  List<MapPlace> results=[];
  @override void initState(){super.initState();locate();}
  @override void dispose(){searchController.dispose();super.dispose();}

  Future<void> locate() async {
    if(mounted)setState(()=>locating=true);
    try{
      if(!await Geolocator.isLocationServiceEnabled()) throw Exception('فعّل خدمة الموقع من الهاتف.');
      var permission=await Geolocator.checkPermission();
      if(permission==LocationPermission.denied) permission=await Geolocator.requestPermission();
      if(permission==LocationPermission.denied||permission==LocationPermission.deniedForever) throw Exception('اسمح لنوفا بالوصول إلى موقعك.');
      final p=await Geolocator.getCurrentPosition(locationSettings:const LocationSettings(accuracy:LocationAccuracy.high));
      final point=LatLng(p.latitude,p.longitude);
      if(!mounted)return;
      setState(()=>me=point);
      mapController.move(point,16);
      await reverseGeocode(point);
    }catch(e){
      if(mounted)setState(()=>locationError=e.toString().replaceFirst('Exception: ',''));
    }finally{
      if(mounted)setState(()=>locating=false);
    }
  }

  Future<void> reverseGeocode(LatLng point) async {
    try{
      final uri=Uri.https('nominatim.openstreetmap.org','/reverse',{
        'lat':point.latitude.toString(),'lon':point.longitude.toString(),
        'format':'jsonv2','accept-language':'ar','zoom':'18','addressdetails':'1',
      });
      final response=await http.get(uri,headers:{'User-Agent':'NovaDelivery/2.1'});
      if(response.statusCode!=200)throw Exception('تعذر قراءة عنوان موقعك');
      final json=Map<String,dynamic>.from(jsonDecode(response.body) as Map);
      final display=(json['display_name']??'موقعك الحالي').toString();
      if(mounted)setState(()=>currentAddress=display);
    }catch(_){
      if(mounted)setState(()=>currentAddress='الموقع الحالي ('+point.latitude.toStringAsFixed(5)+', '+point.longitude.toStringAsFixed(5)+')');
    }
  }

  Future<void> searchPlaces(String raw) async {
    final q=raw.trim();
    if(q.length<2)return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(()=>searching=true);
    try{
      final uri=Uri.https('nominatim.openstreetmap.org','/search',{
        'q':q,'format':'jsonv2','accept-language':'ar','addressdetails':'1','limit':'12',
      });
      final response=await http.get(uri,headers:{'User-Agent':'NovaDelivery/2.1'});
      if(response.statusCode!=200)throw Exception('تعذر البحث على الخريطة');
      final rawResults=jsonDecode(response.body) as List;
      final places=<MapPlace>[];
      for(final item in rawResults){
        final m=Map<String,dynamic>.from(item as Map);
        final lat=double.tryParse(m['lat']?.toString()??'');
        final lon=double.tryParse(m['lon']?.toString()??'');
        if(lat==null||lon==null)continue;
        places.add(MapPlace((m['display_name']??m['name']??q).toString(),lat,lon));
      }
      if(mounted){
        setState(()=>results=places);
        if(places.isNotEmpty)mapController.move(LatLng(places.first.lat,places.first.lng),15.5);
      }
    }catch(e){
      if(mounted)showFeature(context,'البحث على الخريطة',e.toString().replaceFirst('Exception: ',''));
    }finally{
      if(mounted)setState(()=>searching=false);
    }
  }

  void selectPlace(MapPlace p){
    mapController.move(LatLng(p.lat,p.lng),16);
    setState(()=>currentAddress=p.name);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override Widget build(BuildContext c){
    final fallback=widget.restaurant==null?const LatLng(31.0445,31.3540):LatLng(widget.restaurant!.lat,widget.restaurant!.lng);
    final center=me??fallback;
    return Scaffold(
      appBar:AppBar(
        title:const BrandHero(),
        actions:[IconButton(tooltip:'موقعي الحالي',onPressed:locate,icon:const Icon(Icons.my_location_rounded,color:orange))],
      ),
      body:Stack(children:[
        FlutterMap(
          mapController:mapController,
          options:MapOptions(initialCenter:center,initialZoom:me==null?14.5:16),
          children:[
            TileLayer(
              urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName:'nova.delivery/2.1',
            ),
            MarkerLayer(markers:[
              if(widget.restaurant!=null)Marker(
                point:LatLng(widget.restaurant!.lat,widget.restaurant!.lng),width:64,height:72,
                child:Container(
                  decoration:BoxDecoration(color:Colors.white,shape:BoxShape.circle,border:Border.all(color:orange,width:3),boxShadow:const[BoxShadow(color:Color(0x33000000),blurRadius:10)]),
                  padding:const EdgeInsets.all(5),
                  child:ClipOval(child:Image.network(widget.restaurant!.image,fit:BoxFit.cover,errorBuilder:(_,error,stack)=>const Icon(Icons.restaurant_rounded,color:orange))),
                ),
              ),
              if(me!=null)Marker(
                point:me!,width:60,height:60,
                child:Container(
                  decoration:BoxDecoration(color:orange,shape:BoxShape.circle,border:Border.all(color:Colors.white,width:4),boxShadow:const[BoxShadow(color:Color(0x44000000),blurRadius:14)]),
                  child:const Icon(Icons.my_location_rounded,color:Colors.white,size:28),
                ),
              ),
            ]),
            RichAttributionWidget(attributions:[TextSourceAttribution('OpenStreetMap contributors')]),
          ],
        ),
        Positioned(top:12,left:12,right:12,child:Column(children:[
          Material(
            color:Colors.white,
            elevation:8,
            borderRadius:BorderRadius.circular(20),
            child:TextField(
              controller:searchController,
              onSubmitted:searchPlaces,
              textInputAction:TextInputAction.search,
              decoration:InputDecoration(
                hintText:'ابحث عن مطعم، شارع، صيدلية، مكان…',
                prefixIcon:const Icon(Icons.search_rounded,color:orange),
                suffixIcon:searching
                  ? const Padding(padding:EdgeInsets.all(14),child:SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:orange)))
                  : IconButton(onPressed:()=>searchPlaces(searchController.text),icon:const Icon(Icons.arrow_forward_rounded,color:orange)),
              ),
            ),
          ),
          if(currentAddress.isNotEmpty)Container(
            margin:const EdgeInsets.only(top:8),
            padding:const EdgeInsets.symmetric(horizontal:14,vertical:11),
            decoration:BoxDecoration(color:Colors.white.withValues(alpha:.96),borderRadius:BorderRadius.circular(18),boxShadow:const[BoxShadow(color:Color(0x14000000),blurRadius:12)]),
            child:Row(children:[
              const Icon(Icons.location_on_rounded,color:orange,size:21),const SizedBox(width:8),
              Expanded(child:Text(currentAddress,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800))),
              IconButton(tooltip:'إظهار موقعي',onPressed:locate,icon:const Icon(Icons.gps_fixed_rounded,color:orange)),
            ]),
          ),
        ])),
        if(results.isNotEmpty)Positioned(left:12,right:12,top:132,bottom:18,child:Container(
          decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),boxShadow:const[BoxShadow(color:Color(0x22000000),blurRadius:24)]),
          child:ListView.separated(
            padding:const EdgeInsets.all(10),
            itemCount:results.length,
            separatorBuilder:(_,__)=>const Divider(height:1),
            itemBuilder:(_,i){
              final p=results[i];
              return ListTile(
                onTap:()=>selectPlace(p),
                leading:const CircleAvatar(backgroundColor:Color(0x12FF5A36),child:Icon(Icons.place_rounded,color:orange)),
                title:Text(p.name,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800)),
                subtitle:Text(p.lat.toStringAsFixed(5)+', '+p.lng.toStringAsFixed(5),style:const TextStyle(color:muted,fontSize:10)),
                trailing:const Icon(Icons.chevron_left_rounded),
              );
            },
          ),
        )),
        if(locationError!=null)Positioned(left:16,right:16,bottom:22,child:Container(
          padding:const EdgeInsets.all(13),
          decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),boxShadow:const[BoxShadow(color:Color(0x22000000),blurRadius:18)]),
          child:Row(children:[const Icon(Icons.info_outline_rounded,color:orange),const SizedBox(width:8),Expanded(child:Text(locationError!,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700))),IconButton(onPressed:locate,icon:const Icon(Icons.refresh_rounded,color:orange))]),
        )),
      ]),
    );
  }
}
class NearbyPlace{final String name,type;final double lat,lng;const NearbyPlace(this.name,this.type,this.lat,this.lng);}
class MapPlace{final String name;final double lat,lng;const MapPlace(this.name,this.lat,this.lng);}
class CategoryPage extends StatelessWidget{
  final String title,category; final void Function(R,M) onAdd;
  const CategoryPage({super.key,required this.title,required this.category,required this.onAdd});
  bool matches(R r){
    final h=(r.type+' '+r.name+' '+r.menu.map((m)=>m.name+' '+m.desc).join(' ')).toLowerCase();
    switch(category){
      case 'برجر':return h.contains('برجر')||h.contains('burger');
      case 'فراخ':return h.contains('فراخ')||h.contains('chicken')||h.contains('دجاج');
      case 'بيتزا':return h.contains('بيتزا')||h.contains('pizza');
      case 'حلويات':return h.contains('حلويات')||h.contains('كيك')||h.contains('dessert');
      case 'مشروبات':return h.contains('مشروب')||h.contains('بيبسي');
      case 'صحي':return h.contains('صحي')||h.contains('سلطة');
      case 'قهوة':return h.contains('كافيه')||h.contains('قهوة')||h.contains('coffee');
      case 'فطار':return h.contains('فطار')||h.contains('breakfast');
      default:return true;
    }
  }
  @override Widget build(BuildContext c){
    final list=data.where(matches).toList();
    return Scaffold(
      appBar:AppBar(title:Text(title)),
      body:ListView(
        padding:const EdgeInsets.all(18),
        children:[
          Container(
            padding:const EdgeInsets.all(20),
            decoration:BoxDecoration(gradient:const LinearGradient(colors:[ink,Color(0xFF303746)]),borderRadius:BorderRadius.circular(26)),
            child:Text('اختيارات '+category,style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900)),
          ),
          const SizedBox(height:16),
          if(list.isEmpty) const Padding(padding:EdgeInsets.all(30),child:Center(child:Text('لا توجد مطاعم مطابقة حالياً'))),
          for(final r in list)
            Padding(
              padding:const EdgeInsets.only(bottom:14),
              child:CardR(
                r:r,
                onTap:()=>Navigator.push(c,MaterialPageRoute(
                  builder:(_)=>RestaurantPage(
                    r:r,fav:false,onFav:(){},
                    onAdd:onAdd,
                  ),
                )),
              ),
            ),
        ],
      ),
    );
  }
}

class SupportCenterPage extends StatefulWidget {
  const SupportCenterPage({super.key});
  @override State<SupportCenterPage> createState()=>_SupportCenterPageState();
}
class _SupportCenterPageState extends State<SupportCenterPage>{
  Map<String,dynamic>? conversation;
  List<Map<String,dynamic>> messages=[];
  RealtimeChannel? channel;
  final input=TextEditingController();
  final scroll=ScrollController();
  bool loading=true,sending=false;
  bool get imageEnabled=>conversation?['status']=='admin_active' && messages.any((m)=>m['sender_type']=='admin');
  @override void initState(){super.initState();_load();}
  @override void dispose(){channel?.unsubscribe();input.dispose();scroll.dispose();super.dispose();}
  Future<void> _load()async{try{conversation=await NovaSupabase.supportConversation();await _refresh();channel=NovaSupabase.watchSupportMessages(conversation!['id'].toString(),_refresh);}catch(e){if(mounted)snack(context,'تعذر فتح مركز المساعدة: $e');}if(mounted)setState(()=>loading=false);}
  Future<void> _refresh()async{final id=conversation?['id']?.toString();if(id==null)return;try{final rows=await NovaSupabase.supportMessages(id);if(mounted)setState(()=>messages=rows);await Future.delayed(const Duration(milliseconds:80));if(scroll.hasClients)scroll.jumpTo(scroll.position.maxScrollExtent);}catch(_){}}
  Future<void> _send()async{final text=input.text.trim();if(text.isEmpty||sending||conversation==null)return;input.clear();setState(()=>sending=true);try{await NovaSupabase.sendSupportMessage(conversation!['id'].toString(),text);await _refresh();}catch(e){if(mounted)snack(context,'تعذر إرسال الرسالة: $e');}if(mounted)setState(()=>sending=false);}
  Future<void> _image()async{if(!imageEnabled||conversation==null)return;final file=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:88,maxWidth:1600);if(file==null)return;try{final url=await NovaSupabase.uploadSupportImage(conversation!['id'].toString(),await file.readAsBytes());await NovaSupabase.sendSupportImage(conversation!['id'].toString(),url);await _refresh();}catch(e){if(mounted)snack(context,'تعذر رفع الصورة: $e');}}
  Widget bubble(Map<String,dynamic> m){final type=(m['sender_type']??'ai').toString(),mine=type=='customer';final image=(m['image_url']??'').toString();return Align(alignment:mine?Alignment.centerLeft:Alignment.centerRight,child:Container(constraints:const BoxConstraints(maxWidth:330),margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:mine?orange:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:mine?Colors.transparent:const Color(0xFFE8E8EA))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if(type!='customer')Padding(padding:const EdgeInsets.only(bottom:4),child:Text(type=='admin'?'مسؤول الدعم':'Nova AI',style:TextStyle(fontSize:10,fontWeight:FontWeight.w900,color:mine?Colors.white70:orange))),if(m['body']!=null&&m['body'].toString().isNotEmpty)Text(m['body'].toString(),style:TextStyle(color:mine?Colors.white:ink,fontWeight:FontWeight.w600,height:1.45)),if(image.isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.network(image,width:240,height:180,fit:BoxFit.cover)))])));}
  @override Widget build(BuildContext c){
    if(loading)return const Center(child:CircularProgressIndicator(color:orange));
    final waiting=conversation?['status']=='waiting_admin';
    return Scaffold(
      backgroundColor:const Color(0xFFF7F7F8),
      appBar:AppBar(
        title:const Text('مركز المساعدة',style:TextStyle(fontWeight:FontWeight.w900)),
        actions:[if(waiting)const Padding(padding:EdgeInsets.all(12),child:Icon(Icons.support_agent_rounded,color:orange))],
      ),
      body:Column(
        children:[
          Container(
            margin:const EdgeInsets.fromLTRB(14,14,14,8),
            padding:const EdgeInsets.all(16),
            decoration:BoxDecoration(color:ink,borderRadius:BorderRadius.circular(24)),
            child:Row(
              children:[
                Container(width:48,height:48,decoration:BoxDecoration(color:orange,borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.auto_awesome,color:Colors.white)),
                const SizedBox(width:12),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  const Text('Nova AI',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:17)),
                  Text(waiting?'تم تحويلك لمسؤول — انتظر الرد هنا':'اسألني عن طلبك أو أي مشكلة في نوفا',style:const TextStyle(color:Colors.white70,fontSize:11)),
                ])),
              ],
            ),
          ),
          Expanded(
            child:ListView.builder(
              controller:scroll,
              padding:const EdgeInsets.fromLTRB(14,8,14,10),
              itemCount:messages.length,
              itemBuilder:(_,i)=>bubble(messages[i]),
            ),
          ),
          SafeArea(
            top:false,
            child:Container(
              padding:const EdgeInsets.fromLTRB(10,8,10,10),
              decoration:const BoxDecoration(color:Colors.white,border:Border(top:BorderSide(color:Color(0xFFEAEAEA)))),
              child:Row(
                crossAxisAlignment:CrossAxisAlignment.end,
                children:[
                  IconButton(onPressed:imageEnabled?_image:null,icon:Icon(Icons.image_outlined,color:imageEnabled?orange:Colors.black26)),
                  Expanded(child:TextField(
                    controller:input,
                    minLines:1,
                    maxLines:5,
                    decoration:InputDecoration(
                      hintText:waiting?'انتظر رد المسؤول...':'اكتب رسالتك...',
                      filled:true,
                      fillColor:const Color(0xFFF4F4F5),
                      border:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide.none),
                      contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:11),
                    ),
                  )),
                  const SizedBox(width:6),
                  IconButton(
                    onPressed:sending?null:_send,
                    style:IconButton.styleFrom(backgroundColor:orange,foregroundColor:Colors.white),
                    icon:sending
                      ?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
                      :const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerSupportChatPage extends StatefulWidget{
  final String conversationId;
  const OwnerSupportChatPage({super.key,required this.conversationId});
  @override State<OwnerSupportChatPage> createState()=>_OwnerSupportChatPageState();
}
class _OwnerSupportChatPageState extends State<OwnerSupportChatPage>{
  List<Map<String,dynamic>> messages=[]; RealtimeChannel? channel; final input=TextEditingController(); bool sending=false;
  @override void initState(){super.initState();_load();}
  @override void dispose(){channel?.unsubscribe();input.dispose();super.dispose();}
  Future<void> _load()async{await _refresh();channel=NovaSupabase.watchSupportMessages(widget.conversationId,_refresh);}
  Future<void> _refresh()async{try{final x=await NovaSupabase.ownerSupportMessages(widget.conversationId);if(mounted)setState(()=>messages=x);}catch(e){if(mounted)snack(context,'تعذر تحميل المحادثة: $e');}}
  Future<void> _send()async{final t=input.text.trim();if(t.isEmpty||sending)return;input.clear();setState(()=>sending=true);try{await NovaSupabase.ownerReplySupport(widget.conversationId,t);await _refresh();}catch(e){if(mounted)snack(context,'تعذر الإرسال: $e');}if(mounted)setState(()=>sending=false);}
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text('عميل مجهول #${widget.conversationId.substring(0,6)}',style:const TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:()async{await NovaSupabase.closeSupportConversation(widget.conversationId);if(c.mounted)Navigator.pop(c);},icon:const Icon(Icons.check_circle_outline,color:orange))]),body:Column(children:[Container(margin:const EdgeInsets.all(14),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFFFFF4F0),borderRadius:BorderRadius.circular(18)),child:const Row(children:[Icon(Icons.privacy_tip_outlined,color:orange),SizedBox(width:8),Expanded(child:Text('المحادثة مجهولة للمالك: لا يتم عرض اسم أو بريد العميل هنا.'))])),Expanded(child:ListView.builder(padding:const EdgeInsets.all(14),itemCount:messages.length,itemBuilder:(_,i){final m=messages[i];final mine=m['sender_type']=='admin';final ai=m['sender_type']=='ai';return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(12),constraints:const BoxConstraints(maxWidth:340),decoration:BoxDecoration(color:mine?orange:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFE7E7E9))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(ai?'Nova AI':mine?'أنت':'العميل',style:TextStyle(fontSize:9,fontWeight:FontWeight.w900,color:mine?Colors.white70:orange)),const SizedBox(height:4),if((m['body']??'').toString().isNotEmpty)Text(m['body'].toString(),style:TextStyle(color:mine?Colors.white:ink)),if((m['image_url']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.only(top:6),child:Image.network(m['image_url'].toString(),width:220,height:160,fit:BoxFit.cover))])));}),),SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(10,6,10,10),child:Row(children:[Expanded(child:TextField(controller:input,maxLines:4,decoration:InputDecoration(hintText:'اكتب رد المسؤول...',filled:true,fillColor:const Color(0xFFF4F4F5),border:OutlineInputBorder(borderRadius:BorderRadius.circular(20),borderSide:BorderSide.none)))),IconButton(onPressed:sending?null:_send,style:IconButton.styleFrom(backgroundColor:orange,foregroundColor:Colors.white),icon:const Icon(Icons.send_rounded))])))]));
}

class OwnerDashboardPage extends StatefulWidget{
  const OwnerDashboardPage({super.key});
  @override State<OwnerDashboardPage> createState()=>_OwnerDashboardPageState();
}
class _OwnerDashboardPageState extends State<OwnerDashboardPage> with SingleTickerProviderStateMixin{
  late final TabController tabs;
  List<Map<String,dynamic>> restaurants=[],orders=[],coupons=[],offers=[],content=[],support=[]; RealtimeChannel? supportChannel; bool loading=true;
  @override void initState(){super.initState();tabs=TabController(length:6,vsync:this);_load();supportChannel=NovaSupabase.watchSupportInbox(_loadSupport);}
  @override void dispose(){tabs.dispose();supportChannel?.unsubscribe();super.dispose();}
  Future<void> _load()async{if(mounted)setState(()=>loading=true);try{restaurants=await NovaSupabase.restaurants();orders=await NovaSupabase.ownerOrders();coupons=await NovaSupabase.ownerCoupons();offers=await NovaSupabase.ownerOffers();content=await NovaSupabase.appContent();support=await NovaSupabase.ownerSupportConversations();}catch(e){if(mounted)snack(context,'تعذر تحميل لوحة المالك: $e');}if(mounted)setState(()=>loading=false);}
  Future<void> _loadSupport()async{try{final x=await NovaSupabase.ownerSupportConversations();if(mounted)setState(()=>support=x);}catch(_){}}
  Widget stat(IconData icon,String title,String value,Color color)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFE9E9EB))),child:Row(children:[Container(width:42,height:42,decoration:BoxDecoration(color:color.withValues(alpha:.1),borderRadius:BorderRadius.circular(14)),child:Icon(icon,color:color)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:muted,fontSize:11)),const SizedBox(height:3),Text(value,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900))]))]));
  Future<void> _addRestaurant()async{final n=TextEditingController(),d=TextEditingController(),p=TextEditingController();await showDialog(context:context,builder:(x)=>AlertDialog(title:const Text('إضافة مطعم'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'اسم المطعم')),TextField(controller:d,decoration:const InputDecoration(labelText:'الوصف')),TextField(controller:p,decoration:const InputDecoration(labelText:'الهاتف'))]),actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),FilledButton(onPressed:()async{try{await NovaSupabase.createRestaurant(name:n.text,description:d.text,phone:p.text);if(x.mounted)Navigator.pop(x);await _load();}catch(e){if(x.mounted)snack(x,'تعذر الإضافة: $e');}},child:const Text('إضافة'))]));n.dispose();d.dispose();p.dispose();}
  Future<void> _editRestaurant(Map<String,dynamic> r)async{final n=TextEditingController(text:'${r['name']??''}'),d=TextEditingController(text:'${r['description']??''}');await showDialog(context:context,builder:(x)=>AlertDialog(title:const Text('تعديل المطعم'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:d,decoration:const InputDecoration(labelText:'الوصف'))]),actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),FilledButton(onPressed:()async{try{await NovaSupabase.updateRestaurant(r['id'].toString(),name:n.text,description:d.text);if(x.mounted)Navigator.pop(x);await _load();}catch(e){if(x.mounted)snack(x,'تعذر الحفظ: $e');}},child:const Text('حفظ'))]));n.dispose();d.dispose();}
  Future<void> _menu(Map<String,dynamic> r)async{final menu=await NovaSupabase.allRestaurantMenu(r['id'].toString());if(!mounted)return;showModalBottomSheet(context:context,isScrollControlled:true,showDragHandle:true,builder:(s)=>Directionality(textDirection:TextDirection.rtl,child:Padding(padding:const EdgeInsets.all(18),child:Column(mainAxisSize:MainAxisSize.min,children:[Text('منيو ${r['name']??''}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:10),SizedBox(height:420,child:ListView(children:menu.map((m)=>ListTile(title:Text('${m['name']??''}',style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${_money(m['price']).toStringAsFixed(0)} ج.م'),trailing:Switch(value:m['is_available']==true,onChanged:(v)async{await NovaSupabase.setMenuItemAvailability(m['id'].toString(),v);setState((){});}),onTap:()async{final n=TextEditingController(text:'${m['name']??''}'),p=TextEditingController(text:'${m['price']??''}');await showDialog(context:s,builder:(d)=>AlertDialog(title:const Text('تعديل الصنف'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:p,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'السعر'))]),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('إلغاء')),FilledButton(onPressed:()async{final price=double.tryParse(p.text);if(price==null)return;await NovaSupabase.updateMenuItem(m['id'].toString(),name:n.text,price:price);if(d.mounted)Navigator.pop(d);setState((){});},child:const Text('حفظ'))]));n.dispose();p.dispose();})).toList())),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()async{final n=TextEditingController(),p=TextEditingController();await showDialog(context:s,builder:(d)=>AlertDialog(title:const Text('إضافة صنف'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:p,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'السعر'))]),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('إلغاء')),FilledButton(onPressed:()async{final price=double.tryParse(p.text);if(n.text.trim().isEmpty||price==null)return;await NovaSupabase.addMenuItemFull(r['id'].toString(),name:n.text,price:price);if(d.mounted)Navigator.pop(d);if(s.mounted)Navigator.pop(s);await _menu(r);},child:const Text('إضافة'))]));n.dispose();p.dispose();},icon:const Icon(Icons.add),label:const Text('إضافة صنف')))]))));
  }
  Future<void> _coupon()async{final code=TextEditingController(),title=TextEditingController(),value=TextEditingController();await showDialog(context:context,builder:(x)=>AlertDialog(title:const Text('كوبون جديد'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:code,decoration:const InputDecoration(labelText:'الكود')),TextField(controller:title,decoration:const InputDecoration(labelText:'العنوان')),TextField(controller:value,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'قيمة الخصم %'))]),actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),FilledButton(onPressed:()async{final v=double.tryParse(value.text);if(v==null)return;try{await NovaSupabase.createCoupon(code:code.text,title:title.text,discountType:'percent',discountValue:v);if(x.mounted)Navigator.pop(x);await _load();}catch(e){if(x.mounted)snack(x,'تعذر إنشاء الكوبون: $e');}},child:const Text('إنشاء'))]));code.dispose();title.dispose();value.dispose();}
  Future<void> _offer()async{final title=TextEditingController(),sub=TextEditingController();await showDialog(context:context,builder:(x)=>AlertDialog(title:const Text('عرض جديد'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:title,decoration:const InputDecoration(labelText:'العنوان')),TextField(controller:sub,decoration:const InputDecoration(labelText:'الوصف'))]),actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),FilledButton(onPressed:()async{try{await NovaSupabase.createOffer(title:title.text,subtitle:sub.text);if(x.mounted)Navigator.pop(x);await _load();}catch(e){if(x.mounted)snack(x,'تعذر إنشاء العرض: $e');}},child:const Text('إنشاء'))]));title.dispose();sub.dispose();}
  Future<void> _contentEdit(Map<String,dynamic> item)async{final v=TextEditingController(text:'${item['text_value']??''}');await showDialog(context:context,builder:(x)=>AlertDialog(title:Text('تعديل ${item['key']}'),content:TextField(controller:v,maxLines:5,decoration:const InputDecoration(labelText:'النص')),actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),FilledButton(onPressed:()async{await NovaSupabase.updateAppContent(item['key'].toString(),v.text);if(x.mounted)Navigator.pop(x);await _load();},child:const Text('حفظ'))]));v.dispose();}
  Widget _overview()=>ListView(padding:const EdgeInsets.all(16),children:[Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[ink,Color(0xFF2B303A)]),borderRadius:BorderRadius.circular(28)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('استوديو نوفا',style:TextStyle(color:Colors.white,fontSize:27,fontWeight:FontWeight.w900)),const SizedBox(height:5),const Text('مركز التحكم في الطلبات والمطاعم والدعم والمحتوى',style:TextStyle(color:Colors.white70)),const SizedBox(height:18),Row(children:[Expanded(child:FilledButton.icon(onPressed:()=>tabs.animateTo(4),style:FilledButton.styleFrom(backgroundColor:orange),icon:const Icon(Icons.support_agent),label:Text(support.isEmpty?'الدعم':'${support.length} طلب دعم'))),const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:_load,style:OutlinedButton.styleFrom(foregroundColor:Colors.white,side:const BorderSide(color:Colors.white24)),icon:const Icon(Icons.refresh),label:const Text('تحديث')))])]),const SizedBox(height:14),stat(Icons.receipt_long,'كل الطلبات','${orders.length}',orange),const SizedBox(height:9),stat(Icons.storefront,'المطاعم','${restaurants.length}',const Color(0xFF6B5CE7)),const SizedBox(height:9),stat(Icons.local_offer,'الكوبونات','${coupons.length}',const Color(0xFF1D9B72)),const SizedBox(height:9),stat(Icons.support_agent,'طلبات الدعم','${support.length}',const Color(0xFFE89B2B))]);
  Widget _orders()=>ListView(padding:const EdgeInsets.all(16),children:[if(orders.isEmpty)const Padding(padding:EdgeInsets.all(30),child:Center(child:Text('لا توجد طلبات حتى الآن'))),...orders.map((o)=>Card(margin:const EdgeInsets.only(bottom:8),child:ListTile(title:Text('${o['restaurant_name']??'مطعم'} • #${_shortId(o['id'])}',style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${o['customer_name']??'عميل'} • ${_money(o['total']).toStringAsFixed(0)} ج.م'),trailing:DropdownButton<String>(value:(o['status']??'pending').toString(),items:const['pending','accepted','preparing','ready','picked_up','on_the_way','delivered','cancelled'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)async{if(v==null)return;await NovaSupabase.ownerUpdateOrderStatus(o['id'].toString(),v);await _load();})))]);
  Widget _catalog()=>ListView(padding:const EdgeInsets.all(16),children:[FilledButton.icon(onPressed:_addRestaurant,icon:const Icon(Icons.add_business),label:const Text('إضافة مطعم')),const SizedBox(height:12),...restaurants.map((r)=>Card(child:ListTile(title:Text('${r['name']??''}',style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${r['description']??''}'),leading:const Icon(Icons.storefront,color:orange),trailing:Wrap(children:[IconButton(onPressed:()=>_menu(r),icon:const Icon(Icons.restaurant_menu)),IconButton(onPressed:()=>_editRestaurant(r),icon:const Icon(Icons.edit_outlined))]))))];
  Widget _marketing()=>ListView(padding:const EdgeInsets.all(16),children:[Row(children:[Expanded(child:FilledButton.icon(onPressed:_coupon,icon:const Icon(Icons.confirmation_num_outlined),label:const Text('كوبون'))),const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:_offer,icon:const Icon(Icons.campaign_outlined),label:const Text('عرض')))]),const SizedBox(height:14),const Text('الكوبونات',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),...coupons.map((x)=>SwitchListTile(title:Text('${x['code']??''} — ${x['title']??''}'),subtitle:Text('${x['discount_value']??0}% خصم'),value:x['is_active']==true,onChanged:(v)async{await NovaSupabase.updateCoupon(x['id'].toString(),{'is_active':v});await _load();})),const SizedBox(height:14),const Text('العروض',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),...offers.map((x)=>SwitchListTile(title:Text('${x['title']??''}'),subtitle:Text('${x['subtitle']??''}'),value:x['is_active']==true,onChanged:(v)async{await NovaSupabase.updateOffer(x['id'].toString(),{'is_active':v});await _load();}))]);
  Widget _support()=>ListView(padding:const EdgeInsets.all(16),children:[if(support.isEmpty)const Padding(padding:EdgeInsets.all(30),child:Center(child:Text('لا توجد محادثات دعم مفتوحة'))),...support.map((x){final waiting=x['status']=='waiting_admin';return Card(child:ListTile(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OwnerSupportChatPage(conversationId:x['id'].toString()))).then((_){_loadSupport();}),leading:Badge(isLabelVisible:waiting,label:const Text('!'),child:const CircleAvatar(backgroundColor:Color(0xFFFFF0EA),child:Icon(Icons.support_agent,color:orange))),title:Text('عميل مجهول #${x['id'].toString().substring(0,6)}',style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(waiting?'العميل ينتظر مسؤولاً':'محادثة مفتوحة مع Nova AI'),trailing:const Icon(Icons.chevron_left));})]);
  Widget _content()=>ListView(padding:const EdgeInsets.all(16),children:[const Text('محتوى التطبيق',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:8),...content.map((x)=>Card(child:ListTile(title:Text('${x['key']??''}',style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('${x['text_value']??x['image_url']??''}',maxLines:2,overflow:TextOverflow.ellipsis),trailing:const Icon(Icons.edit_outlined),onTap:()=>_contentEdit(x))))]);
  @override Widget build(BuildContext c){if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator(color:orange)));return Directionality(textDirection:TextDirection.rtl,child:Scaffold(backgroundColor:const Color(0xFFF7F7F8),appBar:AppBar(title:const Text('لوحة نوفا',style:TextStyle(fontWeight:FontWeight.w900)),bottom:TabBar(controller:tabs,isScrollable:true,tabAlignment:TabAlignment.start,tabs:const[Tab(icon:Icon(Icons.dashboard_outlined),text:'نظرة عامة'),Tab(icon:Icon(Icons.receipt_long),text:'الطلبات'),Tab(icon:Icon(Icons.storefront),text:'المطاعم'),Tab(icon:Icon(Icons.local_offer),text:'التسويق'),Tab(icon:Icon(Icons.support_agent),text:'الدعم'),Tab(icon:Icon(Icons.edit_note),text:'المحتوى')])),body:TabBarView(controller:tabs,children:[_overview(),_orders(),_catalog(),_marketing(),_support(),_content()])));
  }
}
class OwnerStudioPage extends OwnerDashboardPage { const OwnerStudioPage({super.key}); }


class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final list = data.where((r) => favoriteRestaurants.contains(r.name)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: list.isEmpty
          ? const Center(child: Text('لم تحفظ أي مطعم بعد'))
          : ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final restaurant = list[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CardR(
                    r: restaurant,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RestaurantPage(
                            r: restaurant,
                            fav: true,
                            onFav: () {},
                            onAdd: (r, m) {},
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
Widget st(BuildContext c, IconData icon, String titleText, String sub, VoidCallback onTap, {Widget? trailing}) {
  return Container(
    margin:const EdgeInsets.only(bottom:9),
    decoration:BoxDecoration(color:Theme.of(c).colorScheme.surface,borderRadius:BorderRadius.circular(18)),
    child:ListTile(
      onTap:onTap,
      leading:Container(
        padding:const EdgeInsets.all(10),
        decoration:BoxDecoration(color:orange.withValues(alpha:.1),borderRadius:BorderRadius.circular(13)),
        child:Icon(icon,color:orange),
      ),
      title:Text(titleText,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:14)),
      subtitle:Text(sub,style:const TextStyle(color:muted,fontSize:11)),
      trailing:trailing??const Icon(Icons.chevron_left),
    ),
  );
}

void showNotifications(BuildContext c) {
  showModalBottomSheet(
    context: c,
    showDragHandle: true,
    builder: (_) => const Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('الإشعارات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          ListTile(leading: Icon(Icons.delivery_dining, color: orange), title: Text('طلبك NV-2841 في الطريق'), subtitle: Text('السائق استلم الطلب وسيصل قريباً')),
          ListTile(leading: Icon(Icons.local_offer, color: orange), title: Text('عرض جديد من بازوكا'), subtitle: Text('اكتشف أحدث العروض في المنصورة')),
          ListTile(leading: Icon(Icons.auto_awesome, color: orange), title: Text('نوفا ترحب بك'), subtitle: Text('مطاعم وفروع وبيانات حقيقية حولك')),
        ]),
      ),
    ),
  );
}

void showFeature(BuildContext c,String titleText,String body){showDialog(context:c,builder:(_)=>AlertDialog(title:Text(titleText),content:Text(body),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('حسناً'))]));}

Future<void> checkout(BuildContext c, List<Line> cart, double total, VoidCallback onSuccess) async {
  if(cart.isEmpty)return;
  final restaurant=cart.first.r;
  if(cart.any((x)=>x.r.name!=restaurant.name)){
    snack(c,'السلة يجب أن تحتوي على مطعم واحد فقط.');
    return;
  }
  if(!NovaSupabase.initialized || NovaSupabase.currentUser==null){
    snack(c,'سجّل الدخول أولاً لإتمام طلب حقيقي.');
    return;
  }
  List<Map<String,dynamic>> addresses=[];
  try{addresses=await NovaSupabase.addresses();}catch(e){snack(c,'تعذر تحميل العناوين: $e');return;}
  Map<String,dynamic>? selected=addresses.cast<Map<String,dynamic>?>().firstWhere((x)=>x?['is_default']==true,orElse:()=>null);
  selected ??=addresses.isNotEmpty?addresses.first:null;
  if(selected==null){
    final created=await addAddressDialog(c);
    if(created==null)return;
    selected=created;
  }
  String payment='cash';
  String notes='';
  if(!c.mounted)return;
  showModalBottomSheet(
    context:c,isScrollControlled:true,showDragHandle:true,
    backgroundColor:Theme.of(c).scaffoldBackgroundColor,
    builder:(sheet)=>StatefulBuilder(builder:(sheet,setSheet)=>Directionality(
      textDirection:TextDirection.rtl,
      child:SafeArea(child:Padding(
        padding:EdgeInsets.fromLTRB(18,8,18,18+MediaQuery.viewInsetsOf(sheet).bottom),
        child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('إتمام الطلب',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)),
          const SizedBox(height:5),const Text('راجع التفاصيل قبل التأكيد',style:TextStyle(color:muted)),
          const SizedBox(height:16),
          st(sheet,Icons.location_on_rounded,'عنوان التوصيل',(selected!['label']??'المنزل').toString()+' • '+(selected!['address']??'').toString(),() async {
            final all=await NovaSupabase.addresses();
            if(!sheet.mounted)return;
            showModalBottomSheet(context:sheet,builder:(_)=>Directionality(textDirection:TextDirection.rtl,child:ListView(padding:const EdgeInsets.all(18),children:[
              const Text('اختر عنواناً',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),
              ...all.map((a)=>ListTile(title:Text((a['label']??'عنوان').toString()),subtitle:Text((a['address']??'').toString()),onTap:(){setSheet(()=>selected=a);Navigator.pop(sheet);})),
              ListTile(leading:const Icon(Icons.add_location_alt,color:orange),title:const Text('إضافة عنوان جديد'),onTap:()async{Navigator.pop(sheet);final created=await addAddressDialog(sheet);if(created!=null&&sheet.mounted)setSheet(()=>selected=created);}),
            ])));
          }),
          st(sheet,Icons.payments_rounded,'طريقة الدفع','الدفع عند الاستلام — الدفع الإلكتروني غير مفعّل بعد',(){
            showModalBottomSheet(context:sheet,builder:(_)=>Directionality(textDirection:TextDirection.rtl,child:Column(mainAxisSize:MainAxisSize.min,children:[
              ListTile(title:const Text('الدفع عند الاستلام'),leading:const Icon(Icons.payments,color:orange),onTap:(){setSheet(()=>payment='cash');Navigator.pop(sheet);}),
              ListTile(title:const Text('بطاقة'),subtitle:const Text('سيتم تفعيلها بعد ربط بوابة دفع حقيقية',style:TextStyle(color:muted,fontSize:11)),leading:const Icon(Icons.credit_card,color:Colors.black26),enabled:false),
              ListTile(title:const Text('محفظة'),subtitle:const Text('سيتم تفعيلها بعد ربط مزود المحفظة',style:TextStyle(color:muted,fontSize:11)),leading:const Icon(Icons.account_balance_wallet,color:Colors.black26),enabled:false),
            ])));
          }),
          st(sheet,Icons.local_offer_rounded,'كود الخصم','اضغط لإدخال كود NOVA20 أو FREEDEL',()=>showDialog(context:sheet,builder:(_)=>AlertDialog(title:const Text('العروض'),content:const Text('NOVA20: خصم 20% على أول طلب\nFREEDEL: توصيل مجاني على المطاعم المختارة'),actions:[TextButton(onPressed:()=>Navigator.pop(sheet),child:const Text('إغلاق'))]))),
          const SizedBox(height:8),
          Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Theme.of(sheet).colorScheme.surface,borderRadius:BorderRadius.circular(20)),child:Column(children:[
            line('قيمة الطلب',total-33),line('التوصيل',25),line('الخدمة',8),const Divider(height:20),line('الإجمالي النهائي',total,bold:true),
          ])),
          const SizedBox(height:14),
          SizedBox(width:double.infinity,child:FilledButton.icon(
            onPressed:() async {
              try{
                setSheet(()=>payment=payment);
                final id=await NovaSupabase.createCustomerOrder(
                  restaurantName:restaurant.name,
                  items:cart.map((x)=>{'name':x.m.name,'quantity':x.qty}).toList(),
                  addressId:selected!['id'].toString(),
                  paymentMethod:payment,
                  notes:notes,
                );
                if(!sheet.mounted)return;
                Navigator.pop(sheet);
                onSuccess();
                snack(c,'تم إنشاء الطلب الحقيقي #'+_shortId(id)+' بنجاح 🎉');
              }catch(e){
                if(sheet.mounted)snack(sheet,'تعذر إنشاء الطلب: $e');
              }
            },
            icon:const Icon(Icons.check_circle_rounded),
            style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(56),backgroundColor:orange),
            label:Text('تأكيد الطلب • '+total.toStringAsFixed(0)+' ج.م'),
          )),
        ]),
      )),
    )),
  );
}

Future<Map<String,dynamic>?> addAddressDialog(BuildContext c) async {
  final label=TextEditingController(text:'المنزل');
  final address=TextEditingController(text:'جاري تحديد عنوانك الحالي…');
  double? lat,lng;
  Map<String,dynamic>? result;
  try{
    if(await Geolocator.isLocationServiceEnabled()){
      var permission=await Geolocator.checkPermission();
      if(permission==LocationPermission.denied)permission=await Geolocator.requestPermission();
      if(permission!=LocationPermission.denied&&permission!=LocationPermission.deniedForever){
        final p=await Geolocator.getCurrentPosition(locationSettings:const LocationSettings(accuracy:LocationAccuracy.high));
        lat=p.latitude;lng=p.longitude;
        try{
          final uri=Uri.https('nominatim.openstreetmap.org','/reverse',{'lat':lat.toString(),'lon':lng.toString(),'format':'jsonv2','accept-language':'ar','zoom':'18','addressdetails':'1'});
          final response=await http.get(uri,headers:{'User-Agent':'NovaDelivery/2.1'});
          if(response.statusCode==200){
            final json=Map<String,dynamic>.from(jsonDecode(response.body) as Map);
            address.text=(json['display_name']??'موقعك الحالي').toString();
          }else{address.text='الموقع الحالي ('+lat.toStringAsFixed(5)+', '+lng.toStringAsFixed(5)+')';}
        }catch(_){address.text='الموقع الحالي ('+lat.toStringAsFixed(5)+', '+lng.toStringAsFixed(5)+')';}
      }
    }
  }catch(_){}
  await showDialog(context:c,builder:(dialog)=>AlertDialog(
    title:const Text('إضافة عنوان'),
    content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:label,decoration:const InputDecoration(labelText:'اسم العنوان')),
      const SizedBox(height:10),
      TextField(controller:address,maxLines:3,decoration:const InputDecoration(labelText:'العنوان بالتفصيل')),
      if(lat!=null)const Padding(padding:EdgeInsets.only(top:8),child:Align(alignment:Alignment.centerRight,child:Text('تم التقاط موقعك الحالي وسيظهر للمندوب مع الطلب.',style:TextStyle(color:muted,fontSize:10)))),
    ]),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('إلغاء')),
      FilledButton(onPressed:()async{
        if(address.text.trim().isEmpty||address.text.contains('جاري تحديد')){snack(dialog,'اكتب العنوان بالتفصيل');return;}
        try{
          result=await NovaSupabase.createAddress(label:label.text.trim().isEmpty?'المنزل':label.text.trim(),address:address.text.trim(),lat:lat,lng:lng);
          if(dialog.mounted)Navigator.pop(dialog);
        }catch(e){if(dialog.mounted)snack(dialog,'تعذر حفظ العنوان: '+e.toString());}
      },child:const Text('حفظ')),
    ],
  ));
  label.dispose();address.dispose();
  return result;
}
