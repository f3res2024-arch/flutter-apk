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

final appCopy = <String,String>{};
final appMedia = <String,String>{};

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
    M('وجبة بازوكا سنايبر','3 قطع دجاج + بطاطس + خبز + كول سلو',225,chicken),M('ريزو بقطع الدجاج','صوص حار أو باربيكيو',95,chicken),M('ساندوتش تشيكن رانش','دجاج مقرمش ورانش وموتزاريلا',145,chicken),M('أصابع الموتزاريلا','3 قطع مع صوص',50,chicken)
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
    final n=name.text.trim(),e=email.text.trim(),p=pass.text;
    if(n.length<2){snack(context,'اكتب اسمك أولاً');return;}
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
    title:widget.role==UserRole.customer?'مرحباً بك في نوفا':'أهلاً يا كابتن',
    subtitle:widget.role==UserRole.customer?'سجّل دخولك وخلّي أكلك علينا.':'سجّل دخولك واستقبل طلباتك بسهولة.',
    child:Column(children:[
      AuthField(controller:name,label:'الاسم',hint:'اكتب اسمك الظاهر في نوفا',icon:Icons.person_outline_rounded),
      const SizedBox(height:13),
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
  final name=TextEditingController(),email=TextEditingController(),pass=TextEditingController(),confirm=TextEditingController();
  @override void dispose(){name.dispose();email.dispose();pass.dispose();confirm.dispose();super.dispose();}
  Future<void> createAccount() async {
    final e=email.text.trim(),p=pass.text;
    if(e.isEmpty||!e.contains('@')){snack(context,'اكتب بريد إلكتروني صحيح');return;}
    if(p.length<6){snack(context,'كلمة المرور يجب أن تكون 6 أحرف على الأقل');return;}
    if(p!=confirm.text){snack(context,'كلمتا المرور غير متطابقتين');return;}
    setState(()=>busy=true);
    try{
      final res=await NovaSupabase.signUp(email:e,password:p,role:widget.role.name,fullName:n);
      if(!mounted)return;
      if(res.session!=null){Navigator.pop(context);snack(context,'تم إنشاء حسابك بنجاح 🎉');}
      else{
        await showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('راجع بريدك الإلكتروني'),content:Text('أرسلنا رسالة تأكيد إلى $e. افتحها لتفعيل الحساب ثم سجّل الدخول.'),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('حسناً'))]));
        if(mounted)Navigator.pop(context);
      }
    }on AuthException catch(e){if(mounted)snack(context,_authMessage(e.message));}
    catch(_){if(mounted)snack(context,'تعذر إنشاء الحساب. حاول مرة أخرى.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext c)=>AuthScaffold(
    onBack:()=>Navigator.pop(c),eyebrow:'حساب جديد',title:'ابدأ مع نوفا',subtitle:'أنشئ حسابك في ثواني وابدأ أول طلب.',
    child:Column(children:[
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
  @override Widget build(BuildContext c)=>TextField(controller:controller,keyboardType:keyboardType,textDirection:keyboardType==TextInputType.emailAddress?TextDirection.ltr:null,textCapitalization:TextCapitalization.none,autocorrect:false,enableSuggestions:keyboardType!=TextInputType.emailAddress,inputFormatters:keyboardType==TextInputType.emailAddress?[FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._+\\-]'))]:null,obscureText:obscureText,textInputAction:TextInputAction.next,decoration:InputDecoration(labelText:label,hintText:hint,prefixIcon:Icon(icon),suffixIcon:suffix));
}

class _GoogleMark extends StatelessWidget{
  const _GoogleMark();
  @override Widget build(BuildContext c)=>Container(width:22,height:22,alignment:Alignment.center,decoration:const BoxDecoration(shape:BoxShape.circle,color:Colors.white),child:const Text('G',style:TextStyle(color:Colors.blue,fontWeight:FontWeight.w900)));
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
  int step=0;
  bool pickedUp=false;
  bool delivered=false;

  LatLng get pickup=>LatLng(
    double.tryParse(widget.order['pickup_lat']?.toString()??'')??31.0440,
    double.tryParse(widget.order['pickup_lng']?.toString()??'')??31.3550,
  );
  LatLng get customer=>LatLng(
    double.tryParse(widget.order['customer_lat']?.toString()??'')??31.0474,
    double.tryParse(widget.order['customer_lng']?.toString()??'')??31.3499,
  );

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
            PolylineLayer(polylines:[Polyline(points:[pickup,customer],strokeWidth:5,color:orange)]),
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
  void open(R r)=>Navigator.push(context,MaterialPageRoute(builder:(_)=>RestaurantPage(r:r,fav:fav.contains(r.name),onFav:()=>setState((){if(!fav.add(r.name))fav.remove(r.name);}),onAdd:add)));
  @override Widget build(BuildContext context){
    final pages=[
      Home(onOpen:open,onMap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MapPage())),onSearch:(q)=>setState(()=>tab=1),onAdd:add),
      SearchPage(onAdd:add,onFav:(r)=>setState((){if(!fav.add(r.name))fav.remove(r.name);}),),
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

class Home extends StatelessWidget {
  final ValueChanged<R> onOpen; final VoidCallback onMap; final ValueChanged<String> onSearch; final void Function(R,M) onAdd;
  const Home({super.key,required this.onOpen,required this.onMap,required this.onSearch,required this.onAdd});
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(18,10,18,110),children:[
    Row(children:[
      Expanded(child:Center(child:RichText(text:TextSpan(children:[
        TextSpan(text:'نوفا ',style:TextStyle(color:ink,fontSize:25,fontWeight:FontWeight.w900)),
        TextSpan(text:'ديليفري',style:TextStyle(color:orange,fontSize:25,fontWeight:FontWeight.w900)),
      ])))),
      IconButton.filledTonal(onPressed:()=>showNotifications(context),icon:const Icon(Icons.notifications_none_rounded,color:ink)),
    ]),
    const SizedBox(height:16),
    Container(
      padding:const EdgeInsets.symmetric(horizontal:15,vertical:4),
      decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(18),boxShadow:const[BoxShadow(color:Color(0x0B000000),blurRadius:18,offset:Offset(0,6))]),
      child:TextField(
        readOnly:true,
        onTap:()=>onSearch(''),
        decoration:const InputDecoration(
          hintText:'إيه نفسك فيه النهارده؟',
          prefixIcon:Icon(Icons.search_rounded,color:orange),
          suffixIcon:Icon(Icons.tune_rounded,color:muted),
          border:InputBorder.none,
          filled:false,
        ),
      ),
    ),
    const SizedBox(height:12),
    InkWell(onTap:onMap,borderRadius:BorderRadius.circular(18),child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(18)),child:const Row(children:[Icon(Icons.location_on_rounded,color:orange),SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('عنوان التوصيل',style:TextStyle(color:muted,fontSize:10)),Text('المنصورة • اختر موقعك على الخريطة',style:TextStyle(fontWeight:FontWeight.bold))])),Icon(Icons.chevron_left_rounded)]))),
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
          Positioned(bottom:14,left:14,child:FilledButton(onPressed:onMap,style:FilledButton.styleFrom(backgroundColor:orange,foregroundColor:Colors.white),child:const Text('افتح الخريطة'))),
        ]),
      ),
    ),
    const SizedBox(height:23),title(appCopy['mood_title']??'اختار إللي على مزاجك','عرض الكل'),const SizedBox(height:11),
    SizedBox(height:112,child:ListView(scrollDirection:Axis.horizontal,children:[Cat(Icons.lunch_dining_rounded,'برجر',onAdd:onAdd),Cat(Icons.restaurant_rounded,'فراخ',onAdd:onAdd),Cat(Icons.local_pizza_rounded,'بيتزا',onAdd:onAdd),Cat(Icons.cake_rounded,'حلويات',onAdd:onAdd),Cat(Icons.local_drink_rounded,'مشروبات',onAdd:onAdd),Cat(Icons.spa_rounded,'صحي',onAdd:onAdd),Cat(Icons.coffee_rounded,'قهوة',onAdd:onAdd),Cat(Icons.breakfast_dining_rounded,'فطار',onAdd:onAdd)])),
    const SizedBox(height:20),
    const Text('عروض معمولة ليك',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),
    const SizedBox(height:11),
    SizedBox(height:122,child:ListView(
      scrollDirection:Axis.horizontal,
      children:[
        _PromoCard(icon:Icons.local_offer_rounded,title:'خصم 20%',sub:'على أول طلب اليوم',code:'NOVA20'),
        _PromoCard(icon:Icons.delivery_dining_rounded,title:'توصيل مجاني',sub:'على مطاعم مختارة',code:'FREEDEL'),
        _PromoCard(icon:Icons.workspace_premium_rounded,title:'نوفا بلس',sub:'مزايا أكثر كل يوم',code:'NOVA+'),
      ],
    )),
    const SizedBox(height:22),title('مطاعم حقيقية حولك','الخريطة'),const SizedBox(height:12),
    ...data.map((r)=>Padding(padding:const EdgeInsets.only(bottom:14),child:CardR(r:r,onTap:()=>onOpen(r)))),
    const SizedBox(height:4),const Text('المصادر: المنيوز و EGMenus • تحقق من البيانات: سبتمبر 2026',style:TextStyle(color:muted,fontSize:10)),
  ]);
}

Widget title(String a,String b)=>Row(children:[Expanded(child:Text(a,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900))),Text(b,style:const TextStyle(color:orange,fontSize:12,fontWeight:FontWeight.bold))]);

class Cat extends StatelessWidget {
  final IconData icon; final String n; final void Function(R,M) onAdd; const Cat(this.icon,this.n,{super.key,required this.onAdd});
  @override Widget build(BuildContext c)=>Material(color:Colors.transparent,child:InkWell(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>CategoryPage(title:n,category:n,onAdd:onAdd))),borderRadius:BorderRadius.circular(22),child:Container(width:104,margin:const EdgeInsets.only(left:10),padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFEDEDEF)),boxShadow:const[BoxShadow(color:Color(0x0A000000),blurRadius:18,offset:Offset(0,7))]),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Container(width:48,height:48,decoration:BoxDecoration(color:orange.withValues(alpha:.10),shape:BoxShape.circle),child:Icon(icon,color:orange,size:25)),const SizedBox(height:7),Text(n,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:12))]))));
}

class _PromoCard extends StatelessWidget{
  final IconData icon; final String title,sub,code;
  const _PromoCard({required this.icon,required this.title,required this.sub,required this.code});
  @override Widget build(BuildContext c)=>InkWell(
    onTap:()=>showDialog(context:c,builder:(_)=>AlertDialog(title:Text(title),content:Text('كود العرض: $code\n\nاضغط نسخ لاستخدامه عند الدفع.'),actions:[TextButton(onPressed:(){Clipboard.setData(ClipboardData(text:code));Navigator.pop(c);snack(c,'تم نسخ الكود $code');},child:const Text('نسخ')),TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إغلاق'))])),
    borderRadius:BorderRadius.circular(22),
    child:Container(
    width:235,margin:const EdgeInsets.only(left:10),padding:const EdgeInsets.all(16),
    decoration:BoxDecoration(
      gradient:const LinearGradient(colors:[ink,Color(0xFF292E39)]),
      borderRadius:BorderRadius.circular(22),
      boxShadow:const[BoxShadow(color:Color(0x18000000),blurRadius:18,offset:Offset(0,7))],
    ),
      child:Row(children:[
      Container(width:46,height:46,decoration:BoxDecoration(color:orange.withValues(alpha:.16),shape:BoxShape.circle),child:Icon(icon,color:orange)),
      const SizedBox(width:11),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
        Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:16)),
        const SizedBox(height:3),Text(sub,style:const TextStyle(color:Colors.white60,fontSize:10)),
        const SizedBox(height:7),Text(code,style:const TextStyle(color:orange,fontSize:9,fontWeight:FontWeight.w900,letterSpacing:1)),
      ])),
    ]),
    ),
  );
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
        else ...list.map((o)=>orderTile(c,o,statusText(o['status']?.toString()??''))),
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
    await showDialog(context:context,builder:(d)=>AlertDialog(
      title:const Text('تعديل الملف الشخصي'),
      content:TextField(controller:name,decoration:const InputDecoration(labelText:'اسمك الظاهر في التطبيق',prefixIcon:Icon(Icons.person_outline))),
      actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('إلغاء')),FilledButton(onPressed:()async{try{await NovaSupabase.updateProfile(fullName:name.text.trim());if(d.mounted)Navigator.pop(d);await load();}catch(e){if(d.mounted)snack(d,'تعذر الحفظ: '+e.toString());}},child:const Text('حفظ'))],
    ));
    name.dispose();
  }
  Future<void> changeAvatar()async{try{final file=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:88,maxWidth:1200);if(file==null)return;final url=await NovaSupabase.uploadAvatar(NovaSupabase.currentUser!.id,await file.readAsBytes());await NovaSupabase.updateProfile(avatarUrl:url);await load();}catch(e){if(mounted)snack(context,'تعذر تحديث الصورة: '+e.toString());}}
  Future<void> logout()async{
    final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:const Text('تأكيد تسجيل الخروج'),content:const Text('هل تريد تسجيل الخروج من حسابك؟'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('تسجيل الخروج'))]));
    if(ok==true){try{await NovaSupabase.signOut();widget.onLogout();}catch(e){if(mounted)snack(context,'تعذر تسجيل الخروج: '+e.toString());}}
  }
  @override Widget build(BuildContext c){
    final name=((profile?['full_name']??NovaSupabase.currentUser?.email?.split('@').first??'مستخدم')).toString();
    final avatar=(profile?['avatar_url']??'').toString();
    final owner=role=='admin';
    return ListView(padding:const EdgeInsets.fromLTRB(18,18,18,110),children:[
      Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(colors:[ink,Color(0xFF2A303B)]),borderRadius:BorderRadius.circular(28)),child:Row(children:[
        GestureDetector(onTap:changeAvatar,child:CircleAvatar(radius:36,backgroundColor:orange,backgroundImage:avatar.isEmpty?null:NetworkImage(avatar),child:avatar.isEmpty?const Icon(Icons.person_rounded,color:Colors.white,size:36):null)),
        const SizedBox(width:14),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(name,style:const TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.w900)),
          const SizedBox(height:4),Text(owner?'حساب المالك':'حساب العميل',style:const TextStyle(color:Colors.white70,fontSize:12)),
          const SizedBox(height:4),Text(NovaSupabase.currentUser?.email??'',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white54,fontSize:10)),
        ])),
        IconButton(onPressed:editProfile,icon:const Icon(Icons.edit_rounded,color:Colors.white)),
      ])),
      const SizedBox(height:18),
      const Text('حسابي',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),
      const SizedBox(height:9),
      st(c,Icons.person_outline_rounded,'الاسم والصورة','غيّر الاسم أو صورة البروفايل',editProfile),
      st(c,Icons.location_on_outlined,'العناوين والخريطة','موقعك الحالي والأماكن القريبة',widget.onMap),
      st(c,Icons.credit_card_rounded,'طرق الدفع','الدفع عند الاستلام متاح حالياً • الدفع الإلكتروني قيد الربط',()=>showFeature(c,'طرق الدفع','اختر طريقة الدفع أثناء إتمام الطلب.')),
      st(c,Icons.favorite_border_rounded,'المفضلة','مطاعم وأطباق محفوظة',()=>showFeature(c,'المفضلة','احفظ ما تحبه من صفحات المطاعم.')),
      st(c,Icons.notifications_none_rounded,'الإشعارات','الطلبات والعروض',()=>showNotifications(c)),
      st(c,Icons.security_rounded,'الأمان والخصوصية','إدارة جلسة الحساب',()=>showFeature(c,'الأمان والخصوصية','حسابك يعمل بجلسة Supabase آمنة.')),
      if(owner) st(c,Icons.tune_rounded,'استوديو المالك','تعديل المطاعم والمنتجات ومحتوى التطبيق',()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const OwnerStudioPage()))),
      st(c,Icons.help_outline_rounded,'مركز المساعدة','الدعم والطلبات',()=>showFeature(c,'مركز المساعدة','افتح طلبك من «طلباتي» للوصول للتتبع والدعم.')),
      st(c,Icons.logout_rounded,'تسجيل الخروج','الخروج من الحساب على هذا الجهاز',logout),
    ]);
  }
}
class CustomerOrderTrackingPage extends StatefulWidget{
  final Map<String,dynamic> order;
  const CustomerOrderTrackingPage({super.key,required this.order});
  @override State<CustomerOrderTrackingPage> createState()=>_CustomerOrderTrackingPageState();
}
class _CustomerOrderTrackingPageState extends State<CustomerOrderTrackingPage>{
  dynamic channel;
  Map<String,dynamic> current;
  _CustomerOrderTrackingPageState():current={};
  @override void initState(){super.initState();current=Map<String,dynamic>.from(widget.order);_watch();}
  void _watch(){
    if(!NovaSupabase.initialized||NovaSupabase.currentUser==null)return;
    channel=NovaSupabase.watchCustomerOrders(() async {
      try{
        final rows=await NovaSupabase.customerOrders();
        final id=widget.order['id'].toString();
        final hit=rows.where((x)=>x['id'].toString()==id).toList();
        if(hit.isNotEmpty&&mounted)setState(()=>current=hit.first);
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
            if(hasCourier)PolylineLayer(polylines:[Polyline(points:[LatLng(clat,clng),LatLng(lat,lng)],strokeWidth:5,color:orange)]),
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
class _MapPageState extends State<MapPage> {
  LatLng? me;
  bool locating=true,loadingNearby=false;
  String? locationError;
  List<NearbyPlace> nearby=[];
  @override void initState(){super.initState();locate();}
  Future<void> locate() async {
    try {
      if(!await Geolocator.isLocationServiceEnabled()) throw Exception('فعّل خدمة الموقع من الهاتف.');
      var permission=await Geolocator.checkPermission();
      if(permission==LocationPermission.denied) permission=await Geolocator.requestPermission();
      if(permission==LocationPermission.denied||permission==LocationPermission.deniedForever) throw Exception('اسمح لنوفا بالوصول إلى موقعك.');
      final p=await Geolocator.getCurrentPosition(locationSettings:const LocationSettings(accuracy:LocationAccuracy.high));
      final point=LatLng(p.latitude,p.longitude);
      if(!mounted)return;
      setState(()=>me=point);
      await loadNearby(point);
    }catch(e){
      if(mounted)setState(()=>locationError=e.toString().replaceFirst('Exception: ',''));
    }
    if(mounted)setState(()=>locating=false);
  }
  Future<void> loadNearby(LatLng p) async {
    if(mounted)setState(()=>loadingNearby=true);
    try {
      final q='[out:json][timeout:15];(node(around:5000,'+p.latitude.toString()+','+p.longitude.toString()+')[amenity=restaurant];node(around:5000,'+p.latitude.toString()+','+p.longitude.toString()+')[amenity=pharmacy];node(around:5000,'+p.latitude.toString()+','+p.longitude.toString()+')[shop=supermarket];);out tags;';
      final u=Uri.parse('https://overpass-api.de/api/interpreter?data='+Uri.encodeQueryComponent(q));
      final r=await http.get(u,headers:{'User-Agent':'NovaDelivery/2.1'});
      if(r.statusCode!=200)throw Exception('تعذر تحميل الأماكن القريبة');
      final j=jsonDecode(r.body) as Map<String,dynamic>;
      final list=<NearbyPlace>[];
      for(final raw in (j['elements'] as List)){
        final e=Map<String,dynamic>.from(raw as Map);
        final t=Map<String,dynamic>.from((e['tags']??{}) as Map);
        final lat=e['lat'] as num?,lng=e['lon'] as num?;
        if(lat==null||lng==null)continue;
        final amen=(t['amenity']??'').toString(),shop=(t['shop']??'').toString();
        final type=amen=='pharmacy'?'صيدلية':shop=='supermarket'?'سوبر ماركت':'مطعم';
        final name=(t['name:ar']??t['name']??type).toString();
        list.add(NearbyPlace(name,type,lat.toDouble(),lng.toDouble()));
      }
      list.sort((x,y)=>const Distance().as(LengthUnit.Meter,p,LatLng(x.lat,x.lng)).compareTo(const Distance().as(LengthUnit.Meter,p,LatLng(y.lat,y.lng))));
      if(mounted)setState(()=>nearby=list.take(50).toList());
    }catch(e){
      if(mounted)setState(()=>locationError=e.toString().replaceFirst('Exception: ',''));
    }
    if(mounted)setState(()=>loadingNearby=false);
  }
  Color markerColor(String type)=>type=='صيدلية'?const Color(0xFF6558E8):type=='سوبر ماركت'?const Color(0xFF1D9B72):orange;
  IconData markerIcon(String type)=>type=='صيدلية'?Icons.local_pharmacy_rounded:type=='سوبر ماركت'?Icons.local_grocery_store_rounded:Icons.restaurant_rounded;
  @override Widget build(BuildContext c){
    final center=me??(widget.restaurant==null?const LatLng(31.0445,31.3540):LatLng(widget.restaurant!.lat,widget.restaurant!.lng));
    final restaurants=widget.restaurant==null?data:[widget.restaurant!];
    return Scaffold(
      appBar:AppBar(title:const BrandHero(),actions:[IconButton(onPressed:locate,icon:const Icon(Icons.my_location_rounded,color:orange))]),
      body:Stack(children:[
        FlutterMap(
          options:MapOptions(initialCenter:center,initialZoom:14.5),
          children:[
            TileLayer(urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png',userAgentPackageName:'nova.delivery/2.1'),
            MarkerLayer(markers:[
              ...restaurants.map((r)=>Marker(
                point:LatLng(r.lat,r.lng),width:62,height:70,
                child:Container(
                  decoration:BoxDecoration(color:Colors.white,shape:BoxShape.circle,border:Border.all(color:orange,width:3),boxShadow:const[BoxShadow(color:Color(0x33000000),blurRadius:10)]),
                  padding:const EdgeInsets.all(5),
                  child:ClipOval(child:Image.network(r.image,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.restaurant_rounded,color:orange))),
                ),
              )),
              ...nearby.map((p)=>Marker(
                point:LatLng(p.lat,p.lng),width:54,height:60,
                child:Container(
                  decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(17),border:Border.all(color:markerColor(p.type),width:2)),
                  child:Icon(markerIcon(p.type),color:markerColor(p.type),size:28),
                ),
              )),
              if(me!=null)Marker(
                point:me!,width:56,height:56,
                child:Container(
                  decoration:BoxDecoration(color:orange,shape:BoxShape.circle,border:Border.all(color:Colors.white,width:4),boxShadow:const[BoxShadow(color:Color(0x44000000),blurRadius:14)]),
                  child:const Icon(Icons.person_pin_circle_rounded,color:Colors.white,size:28),
                ),
              ),
            ]),
            RichAttributionWidget(attributions:[TextSourceAttribution('OpenStreetMap contributors')]),
          ],
        ),
        Positioned(top:14,right:14,left:14,child:Container(
          padding:const EdgeInsets.symmetric(horizontal:14,vertical:12),
          decoration:BoxDecoration(color:Colors.white.withValues(alpha:.96),borderRadius:BorderRadius.circular(18)),
          child:Row(children:[
            Icon(locating?Icons.gps_not_fixed_rounded:Icons.gps_fixed_rounded,color:orange),
            const SizedBox(width:10),
            Expanded(child:Text(loadingNearby?'جاري البحث عن الالمطاعم والصيدليات والسوبر ماركت القريبة…':locationError??(locating?'جاري تحديد موقعك…':'أنت ظاهر على الخريطة الآن'),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:13))),
          ]),
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
class OwnerStudioPage extends StatefulWidget {
  const OwnerStudioPage({super.key});
  @override State<OwnerStudioPage> createState()=>_OwnerStudioPageState();
}
class _OwnerStudioPageState extends State<OwnerStudioPage> {
  List<Map<String,dynamic>> restaurants=[];
  List<Map<String,dynamic>> content=[];
  bool loading=true;

  @override void initState(){super.initState();load();}
  Future<void> load() async {
    try {
      restaurants=await NovaSupabase.restaurants();
      content=await NovaSupabase.appContent();
    } catch(_) {}
    if(mounted)setState(()=>loading=false);
  }

  Future<void> editRestaurant(Map<String,dynamic> r) async {
    final n=TextEditingController(text:r['name']?.toString()??'');
    final d=TextEditingController(text:r['description']?.toString()??'');
    await showDialog(context:context,builder:(x)=>AlertDialog(
      title:const Text('تعديل المطعم'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:n,decoration:const InputDecoration(labelText:'اسم المطعم')),
        TextField(controller:d,decoration:const InputDecoration(labelText:'الوصف')),
        const SizedBox(height:8),
        OutlinedButton.icon(
          onPressed:() async {
            final file=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:88,maxWidth:1600);
            if(file==null)return;
            try {
              final url=await NovaSupabase.uploadRestaurantImage(r['id'].toString(),await file.readAsBytes());
              if(url!=null)await NovaSupabase.updateRestaurant(r['id'].toString(),logoUrl:url,coverUrl:url);
              if(x.mounted)snack(x,'تم تحديث صورة المطعم');
            } catch(e) { if(x.mounted)snack(x,'تعذر رفع الصورة: '+e.toString()); }
          },
          icon:const Icon(Icons.image_rounded),label:const Text('تغيير صورة المطعم'),
        ),
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),
        FilledButton(
          onPressed:() async {
            try {
              await NovaSupabase.updateRestaurant(r['id'].toString(),name:n.text.trim(),description:d.text.trim());
              if(x.mounted)Navigator.pop(x);
              await load();
            } catch(e) { if(x.mounted)snack(x,'تعذر الحفظ: '+e.toString()); }
          },
          child:const Text('حفظ'),
        ),
      ],
    ));
    n.dispose();d.dispose();
  }

  Future<void> editMenu(String id) async {
    final items=await NovaSupabase.restaurantMenu(id);
    if(!mounted)return;
    await showModalBottomSheet(
      context:context,showDragHandle:true,isScrollControlled:true,
      builder:(x)=>ListView(
        padding:const EdgeInsets.all(18),
        children:[
          const Text('المنتجات',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),
          const SizedBox(height:12),
          ...items.map((m)=>ListTile(
            leading:ClipRRect(borderRadius:BorderRadius.circular(10),child:Image.network((m['image_url']??burger).toString(),width:48,height:48,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.fastfood,color:orange))),
            title:Text((m['name']??'').toString()),
            subtitle:Text((m['price']??0).toString()+' ج.م'),
            trailing:IconButton(icon:const Icon(Icons.edit,color:orange),onPressed:(){Navigator.pop(x);editMenuItem(m);}),
          )),
          FilledButton.icon(onPressed:(){Navigator.pop(x);addMenuItem(id);},icon:const Icon(Icons.add),label:const Text('إضافة منتج')),
        ],
      ),
    );
  }

  Future<void> editMenuItem(Map<String,dynamic> m) async {
    final n=TextEditingController(text:m['name']?.toString()??'');
    final p=TextEditingController(text:m['price']?.toString()??'');
    await showDialog(context:context,builder:(x)=>AlertDialog(
      title:const Text('تعديل المنتج'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:n,decoration:const InputDecoration(labelText:'اسم المنتج')),
        TextField(controller:p,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'السعر')),
        const SizedBox(height:8),
        OutlinedButton.icon(
          onPressed:() async {
            final file=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:88,maxWidth:1600);
            if(file==null)return;
            try {
              final url=await NovaSupabase.uploadMenuImage(m['id'].toString(),await file.readAsBytes());
              if(url!=null)await NovaSupabase.updateMenuItem(m['id'].toString(),imageUrl:url);
              if(x.mounted)snack(x,'تم تحديث صورة المنتج');
            } catch(e) { if(x.mounted)snack(x,'تعذر رفع الصورة: '+e.toString()); }
          },
          icon:const Icon(Icons.image_rounded),label:const Text('تغيير صورة المنتج'),
        ),
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),
        FilledButton(
          onPressed:() async {
            try {
              await NovaSupabase.updateMenuItem(m['id'].toString(),name:n.text.trim(),price:double.parse(p.text));
              if(x.mounted)Navigator.pop(x);
              await load();
            } catch(e) { if(x.mounted)snack(x,'تعذر التحديث: '+e.toString()); }
          },
          child:const Text('حفظ'),
        ),
      ],
    ));
    n.dispose();p.dispose();
  }

  Future<void> addMenuItem(String id) async {
    final n=TextEditingController();
    final p=TextEditingController();
    await showDialog(context:context,builder:(x)=>AlertDialog(
      title:const Text('إضافة منتج'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:n,decoration:const InputDecoration(labelText:'اسم المنتج')),
        TextField(controller:p,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'السعر')),
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),
        FilledButton(onPressed:()async{
          try{await NovaSupabase.addMenuItem(id,name:n.text.trim(),price:double.parse(p.text));if(x.mounted)Navigator.pop(x);await load();}
          catch(e){if(x.mounted)snack(x,'تعذر الإضافة: '+e.toString());}
        },child:const Text('إضافة')),
      ],
    ));
    n.dispose();p.dispose();
  }

  Future<void> editContent(Map<String,dynamic> r) async {
    final v=TextEditingController(text:r['text_value']?.toString()??'');
    await showDialog(context:context,builder:(x)=>AlertDialog(
      title:const Text('تعديل محتوى التطبيق'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:v,maxLines:3,decoration:const InputDecoration(labelText:'النص')),
        const SizedBox(height:8),
        OutlinedButton.icon(
          onPressed:() async {
            final file=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:88,maxWidth:1600);
            if(file==null)return;
            try {
              final url=await NovaSupabase.uploadContentImage(r['key'].toString(),await file.readAsBytes());
              if(url!=null){await NovaSupabase.updateAppContentImage(r['key'].toString(),url);appMedia[r['key'].toString()]=url;}
              if(x.mounted)snack(x,'تم تحديث صورة المحتوى');
            } catch(e) { if(x.mounted)snack(x,'تعذر رفع الصورة: '+e.toString()); }
          },
          icon:const Icon(Icons.image_rounded),label:const Text('تغيير الصورة'),
        ),
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),
        FilledButton(onPressed:()async{
          try{await NovaSupabase.updateAppContent(r['key'].toString(),v.text);appCopy[r['key'].toString()]=v.text;if(x.mounted)Navigator.pop(x);await load();}
          catch(e){if(x.mounted)snack(x,'تعذر الحفظ: '+e.toString());}
        },child:const Text('حفظ')),
      ],
    ));
    v.dispose();
  }

  @override Widget build(BuildContext c){
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator(color:orange)));
    final widgets=<Widget>[
      const Text('استوديو المالك',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900)),
      const SizedBox(height:6),
      const Text('المالك فقط: المنتجات والأسعار والصور والمطاعم والنصوص ومحتوى الواجهة.',style:TextStyle(color:muted)),
      const SizedBox(height:18),
      ...restaurants.map((r)=>Card(
        child:ListTile(
          leading:const Icon(Icons.restaurant_rounded,color:orange),
          title:Text((r['name']??'').toString()),
          trailing:Wrap(children:[
            IconButton(onPressed:()=>editRestaurant(r),icon:const Icon(Icons.edit,color:orange)),
            IconButton(onPressed:()=>editMenu(r['id'].toString()),icon:const Icon(Icons.inventory_2,color:orange)),
          ]),
        ),
      )),
      const SizedBox(height:16),
      const Text('نصوص التطبيق',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),
      ...content.map((r)=>st(c,Icons.text_fields,r['key'].toString(),r['text_value']?.toString()??'',()=>editContent(r))),
    ];
    return Scaffold(appBar:AppBar(title:const BrandHero()),body:ListView(padding:const EdgeInsets.all(18),children:widgets));
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
  final address=TextEditingController();
  Map<String,dynamic>? result;
  await showDialog(context:c,builder:(dialog)=>AlertDialog(
    title:const Text('إضافة عنوان'),
    content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:label,decoration:const InputDecoration(labelText:'اسم العنوان')),
      const SizedBox(height:10),
      TextField(controller:address,maxLines:3,decoration:const InputDecoration(labelText:'العنوان بالتفصيل')),
    ]),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('إلغاء')),
      FilledButton(onPressed:() async {
        if(address.text.trim().isEmpty){snack(dialog,'اكتب العنوان بالتفصيل');return;}
        try{
          result=await NovaSupabase.createAddress(label:label.text.trim().isEmpty?'المنزل':label.text.trim(),address:address.text.trim());
          if(dialog.mounted)Navigator.pop(dialog);
        }catch(e){if(dialog.mounted)snack(dialog,'تعذر حفظ العنوان: $e');}
      },child:const Text('حفظ')),
    ],
  ));
  label.dispose();address.dispose();
  return result;
}
