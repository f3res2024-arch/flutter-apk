import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'core/supabase_service.dart';
import 'owner_control_center.dart';

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
      for(final row in copy){ final k=(row['key']??'').toString(); final v=(row['text_value']??'').toString(); final image=(row['image_url']??'').toString(); if(k.isNotEmpty)appCopy[k]=v; if(k.isNotEmpty&&image.isNotEmpty)appMedia[k]=image; }
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
      useMaterial3:true,brightness:Brightness.light,
      fontFamily:'NotoSansArabic',
      colorScheme:ColorScheme.fromSeed(seedColor:orange,brightness:Brightness.light,surface:Colors.white),
      scaffoldBackgroundColor:Colors.white,
      appBarTheme:const AppBarTheme(elevation:0,scrolledUnderElevation:0,backgroundColor:Colors.white,surfaceTintColor:Colors.transparent,centerTitle:true,titleTextStyle:TextStyle(fontSize:20,fontWeight:FontWeight.w900,color:ink),iconTheme:IconThemeData(color:ink)),
      cardTheme:CardThemeData(elevation:0,margin:EdgeInsets.zero,color:Colors.white,shadowColor:Color(0x12000000),surfaceTintColor:Colors.transparent,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(24))),
      inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Colors.white,contentPadding:const EdgeInsets.symmetric(horizontal:17,vertical:16),border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide(color:orange,width:1.4))),
      filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(backgroundColor:orange,foregroundColor:Colors.white,minimumSize:const Size.fromHeight(54),elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(17)),textStyle:const TextStyle(fontWeight:FontWeight.w900,fontSize:14))),
      outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(minimumSize:const Size.fromHeight(52),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(17)),side:const BorderSide(color:Color(0xFFE8E8EA)),textStyle:const TextStyle(fontWeight:FontWeight.w800))),
      navigationBarTheme:NavigationBarThemeData(height:76,elevation:0,backgroundColor:Colors.white,indicatorColor:orange.withValues(alpha:.12),labelTextStyle:WidgetStateProperty.resolveWith<TextStyle>((states)=>TextStyle(fontSize:10,fontWeight:FontWeight.w800,color:states.contains(WidgetState.selected)?orange:muted))),
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

  @override
  Widget build(BuildContext c)=>Scaffold(
    backgroundColor:Colors.white,
    body:SafeArea(
      child:Column(
        children:[
          Container(
            width:double.infinity,
            padding:const EdgeInsets.fromLTRB(24,24,24,30),
            decoration:const BoxDecoration(
              gradient:LinearGradient(
                begin:Alignment.topRight,
                end:Alignment.bottomLeft,
                colors:[Color(0xFFFF6B47),orange],
              ),
              borderRadius:BorderRadius.vertical(bottom:Radius.circular(38)),
            ),
            child:Column(
              children:[
                Container(
                  padding:const EdgeInsets.symmetric(horizontal:20,vertical:14),
                  decoration:BoxDecoration(
                    color:Colors.white.withValues(alpha:.08),
                    borderRadius:BorderRadius.circular(28),
                    border:Border.all(color:Colors.white.withValues(alpha:.32),width:1.2),
                    boxShadow:const[
                      BoxShadow(color:Color(0x22000000),blurRadius:24,offset:Offset(0,10)),
                      BoxShadow(color:Color(0x33FFFFFF),blurRadius:10,spreadRadius:-4),
                    ],
                  ),
                  child:Row(
                    mainAxisSize:MainAxisSize.min,
                    children:[
                      const Text(
                        'نوفا',
                        style:TextStyle(
                          color:Colors.white,
                          fontSize:44,
                          fontWeight:FontWeight.w900,
                          letterSpacing:-1.2,
                          shadows:[Shadow(color:Color(0x66000000),blurRadius:10,offset:Offset(0,3))],
                        ),
                      ),
                      const SizedBox(width:9),
                      Stack(
                        alignment:Alignment.center,
                        children:[
                          Text(
                            'ديليفري',
                            style:TextStyle(
                              foreground:Paint()
                                ..style=PaintingStyle.stroke
                                ..strokeWidth=4
                                ..color=Colors.white.withValues(alpha:.78),
                              fontSize:44,
                              fontWeight:FontWeight.w900,
                              letterSpacing:-1.2,
                            ),
                          ),
                          const Text(
                            'ديليفري',
                            style:TextStyle(
                              color:orange,
                              fontSize:44,
                              fontWeight:FontWeight.w900,
                              letterSpacing:-1.2,
                              shadows:[
                                Shadow(color:Color(0x66FFFFFF),blurRadius:8,offset:Offset(0,1)),
                                Shadow(color:Color(0x44000000),blurRadius:10,offset:Offset(0,3)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:SingleChildScrollView(
              padding:const EdgeInsets.fromLTRB(20,26,20,24),
              child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  const Text('إنت داخل نوفا بصفتك إيه؟',style:TextStyle(color:ink,fontSize:20,fontWeight:FontWeight.w900)),
                  const SizedBox(height:6),
                  const Text('اختار حسابك علشان نجهز لك التجربة المناسبة.',style:TextStyle(color:muted,fontSize:12)),
                  const SizedBox(height:20),
                  _NovaRoleCard(
                    icon:Icons.person_rounded,
                    title:'أنا عميل',
                    subtitle:'اطلب أكلك، تابع طلبك، واستمتع',
                    badge:'الأكثر استخداماً',
                    onTap:()=>onRole(UserRole.customer),
                  ),
                  const SizedBox(height:14),
                  _NovaRoleCard(
                    icon:Icons.two_wheeler_rounded,
                    title:'أنا مندوب',
                    subtitle:'استقبل الطلبات، سلّم أسرع، واكسب أكثر',
                    onTap:()=>onRole(UserRole.courier),
                    secondary:true,
                  ),
                  const SizedBox(height:24),
                  Container(
                    width:double.infinity,
                    padding:const EdgeInsets.all(15),
                    decoration:BoxDecoration(
                      color:const Color(0xFFFFF6F2),
                      borderRadius:BorderRadius.circular(18),
                      border:Border.all(color:const Color(0xFFFFE1D8)),
                    ),
                    child:const Row(
                      children:[
                        Icon(Icons.verified_user_rounded,color:orange,size:20),
                        SizedBox(width:10),
                        Expanded(
                          child:Text(
                            'تسجيلك آمن، وبيانات حسابك بتتخزن بشكل محمي.',
                            style:TextStyle(color:ink,fontSize:11,fontWeight:FontWeight.w700,height:1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _NovaRoleCard extends StatelessWidget{
  final IconData icon;
  final String title,subtitle;
  final String? badge;
  final VoidCallback onTap;
  final bool secondary;

  const _NovaRoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.secondary=false,
  });

  @override
  Widget build(BuildContext c)=>Material(
    color:Colors.transparent,
    child:InkWell(
      onTap:onTap,
      borderRadius:BorderRadius.circular(24),
      child:Container(
        padding:const EdgeInsets.all(16),
        decoration:BoxDecoration(
          color:Colors.white,
          borderRadius:BorderRadius.circular(24),
          border:Border.all(color:secondary?const Color(0xFFE8E8EA):const Color(0xFFFFD4C9),width:1.2),
          boxShadow:const[
            BoxShadow(color:Color(0x12000000),blurRadius:22,offset:Offset(0,10)),
          ],
        ),
        child:Row(
          children:[
            Container(
              width:58,
              height:58,
              decoration:BoxDecoration(
                gradient:secondary
                  ? const LinearGradient(colors:[Color(0xFFFFF0EB),Color(0xFFFFE2D9)])
                  : const LinearGradient(colors:[orange,Color(0xFFFF784F)]),
                borderRadius:BorderRadius.circular(19),
              ),
              child:Icon(icon,color:secondary?orange:Colors.white,size:28),
            ),
            const SizedBox(width:14),
            Expanded(
              child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  if(badge!=null) ...[
                    Container(
                      padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),
                      decoration:BoxDecoration(color:const Color(0xFFFFF0EB),borderRadius:BorderRadius.circular(20)),
                      child:Text(badge!,style:const TextStyle(color:orange,fontSize:9,fontWeight:FontWeight.w900)),
                    ),
                    const SizedBox(height:6),
                  ],
                  Text(title,style:const TextStyle(color:ink,fontSize:18,fontWeight:FontWeight.w900)),
                  const SizedBox(height:3),
                  Text(subtitle,style:const TextStyle(color:muted,fontSize:11,fontWeight:FontWeight.w600,height:1.35)),
                ],
              ),
            ),
            const SizedBox(width:10),
            Container(
              width:38,
              height:38,
              decoration:BoxDecoration(
                color:secondary?const Color(0xFFFFF3EF):orange,
                shape:BoxShape.circle,
              ),
              child:Icon(Icons.arrow_back_rounded,color:secondary?orange:Colors.white,size:19),
            ),
          ],
        ),
      ),
    ),
  );
}

class BrandHero extends StatelessWidget {
  const BrandHero({super.key});
  @override
  Widget build(BuildContext c)=>Center(
    child:Text.rich(
      const TextSpan(children:[
        TextSpan(text:'نوفا ',style:TextStyle(color:ink,fontSize:30,fontWeight:FontWeight.w900)),
        TextSpan(text:'ديليفري',style:TextStyle(color:orange,fontSize:30,fontWeight:FontWeight.w900)),
      ]),
      textAlign:TextAlign.center,
      textDirection:TextDirection.rtl,
      maxLines:1,
      overflow:TextOverflow.visible,
    ),
  );
}

class LoginScreen extends StatefulWidget {
  final UserRole role; final VoidCallback onBack,onSuccess;
  const LoginScreen({super.key,required this.role,required this.onBack,required this.onSuccess});
  @override State<LoginScreen> createState()=>_LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen>{
  bool hide=true,busy=false;
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
    }finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext c)=>AuthScaffold(
    onBack:widget.onBack,
    eyebrow:'تسجيل الدخول',
    title:'مرحباً بك',
    subtitle:widget.role==UserRole.customer?'سجّل دخولك وخلّي أكلك علينا.':'سجّل دخولك واستقبل طلباتك بسهولة.',
    child:Column(children:[
      AuthField(controller:email,label:'البريد الإلكتروني',hint:'name@example.com',icon:Icons.mail_outline_rounded,keyboardType:TextInputType.emailAddress),
      const SizedBox(height:13),
      AuthField(controller:pass,label:'كلمة المرور',hint:'••••••••',icon:Icons.lock_outline_rounded,obscureText:hide,suffix:IconButton(onPressed:()=>setState(()=>hide=!hide),icon:Icon(hide?Icons.visibility_outlined:Icons.visibility_off_outlined))),
      Align(alignment:Alignment.centerRight,child:TextButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>ForgotPasswordScreen(role:widget.role))),child:const Text('نسيت كلمة المرور؟',style:TextStyle(color:orange,fontWeight:FontWeight.w800)))),
      const SizedBox(height:3),
      FilledButton(onPressed:busy?null:submit,child:busy?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('تسجيل الدخول')),
      const SizedBox(height:18),
      Row(mainAxisAlignment:MainAxisAlignment.center,children:[
        const Text('ليس لديك حساب؟',style:TextStyle(color:muted)),
        TextButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>SignupScreen(role:widget.role))),child:const Text('إنشاء حساب',style:TextStyle(color:orange,fontWeight:FontWeight.w900))),
      ]),
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
        if(mounted)snack(context,'تم إنشاء حسابك بنجاح');
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
          snack(context,'تم تأكيد بريدك وإنشاء حسابك بنجاح');
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
      if(!mounted)return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder:(_)=>PasswordRecoveryOtpScreen(email:e,role:widget.role)),
      );
    }on AuthException catch(e){
      if(mounted)snack(context,_authMessage(e.message));
    }catch(_){
      if(mounted)snack(context,'تعذر إرسال رمز الاستعادة. حاول مرة أخرى.');
    }finally{
      if(mounted)setState(()=>busy=false);
    }
  }

  @override Widget build(BuildContext c)=>AuthScaffold(
    onBack:()=>Navigator.pop(c),
    eyebrow:'استعادة الحساب',
    title:'نسيت كلمة المرور؟',
    subtitle:'اكتب بريدك وسنرسل لك رمزاً من 6 أرقام لإعادة تعيين كلمة المرور.',
    child:Column(children:[
      AuthField(controller:email,label:'البريد الإلكتروني',hint:'name@example.com',icon:Icons.mail_outline_rounded,keyboardType:TextInputType.emailAddress),
      const SizedBox(height:18),
      FilledButton(
        onPressed:busy?null:send,
        child:busy?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('إرسال رمز الاستعادة'),
      ),
    ]),
  );
}

class PasswordRecoveryOtpScreen extends StatefulWidget{
  final String email;
  final UserRole role;
  const PasswordRecoveryOtpScreen({super.key,required this.email,required this.role});
  @override State<PasswordRecoveryOtpScreen> createState()=>_PasswordRecoveryOtpScreenState();
}
class _PasswordRecoveryOtpScreenState extends State<PasswordRecoveryOtpScreen>{
  final code=TextEditingController();
  bool busy=false,resending=false;
  @override void dispose(){code.dispose();super.dispose();}

  Future<void> verify() async {
    final token=code.text.trim();
    if(token.length!=6){snack(context,'اكتب رمز الاستعادة المكوّن من 6 أرقام');return;}
    setState(()=>busy=true);
    try{
      final res=await NovaSupabase.verifyPasswordRecoveryOtp(email:widget.email,token:token);
      if(res.session==null)throw const AuthException('تعذر إنشاء جلسة الاستعادة.');
      if(!mounted)return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:(_)=>UpdatePasswordScreen(onDone:()=>Navigator.pop(context)),
        ),
      );
    }on AuthException catch(e){
      if(mounted)snack(context,_authMessage(e.message));
    }catch(_){
      if(mounted)snack(context,'رمز الاستعادة غير صحيح أو انتهت صلاحيته.');
    }finally{
      if(mounted)setState(()=>busy=false);
    }
  }

  Future<void> resend() async {
    if(resending)return;
    setState(()=>resending=true);
    try{
      await NovaSupabase.resendPasswordResetOtp(widget.email);
      if(mounted)snack(context,'تم إرسال رمز استعادة جديد إلى بريدك الإلكتروني.');
    }on AuthException catch(e){
      if(mounted)snack(context,_authMessage(e.message));
    }catch(_){
      if(mounted)snack(context,'تعذر إرسال رمز جديد حالياً.');
    }finally{
      if(mounted)setState(()=>resending=false);
    }
  }

  @override Widget build(BuildContext c)=>AuthScaffold(
    onBack:()=>Navigator.pop(c),
    eyebrow:'استعادة الحساب',
    title:'أدخل رمز الاستعادة',
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
          labelText:'رمز الاستعادة',
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
    try{await NovaSupabase.updatePassword(pass.text);if(mounted){snack(context,'تم تغيير كلمة المرور بنجاح');widget.onDone();}}
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
                    crossAxisAlignment:CrossAxisAlignment.stretch,
                    mainAxisAlignment:MainAxisAlignment.center,
                    children:[
                      Row(
                        crossAxisAlignment:CrossAxisAlignment.center,
                        children:[
                          Container(
                            padding:const EdgeInsets.symmetric(horizontal:11,vertical:7),
                            decoration:BoxDecoration(color:orange.withValues(alpha:.10),borderRadius:BorderRadius.circular(30)),
                            child:Text(eyebrow,style:const TextStyle(color:orange,fontSize:11,fontWeight:FontWeight.w900)),
                          ),
                          const SizedBox(width:10),
                          Expanded(
                            child:Text(
                              title,
                              textAlign:TextAlign.right,
                              style:const TextStyle(fontSize:30,fontWeight:FontWeight.w900,height:1.1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height:7),
                      Text(subtitle,textAlign:TextAlign.right,style:const TextStyle(color:muted,fontSize:13,height:1.5)),
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
                  snack(c,'تم تحديد الاستلام من المطعم. الآن وجهتك العميل');
                }else{
                  setState(()=>delivered=true);
                  snack(c,'تم تسليم الطلب بنجاح');
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
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تمت إضافة المنتج للسلة'),duration:Duration(milliseconds:900)));
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
                  NavigationDestination(icon:Icon(Icons.home_outlined,color:muted),selectedIcon:Icon(Icons.home_rounded,color:orange),label:'الرئيسية'),
                  NavigationDestination(icon:Icon(Icons.search_rounded,color:muted),selectedIcon:Icon(Icons.search_rounded,color:orange),label:'اكتشف'),
                  NavigationDestination(icon:Icon(Icons.receipt_long_outlined,color:muted),selectedIcon:Icon(Icons.receipt_long_rounded,color:orange),label:'طلباتي'),
                  NavigationDestination(icon:Icon(Icons.person_outline,color:muted),selectedIcon:Icon(Icons.person_rounded,color:orange),label:'حسابي'),
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
                      NavigationRailDestination(icon:Icon(Icons.home_outlined,color:muted),selectedIcon:Icon(Icons.home_rounded,color:orange),label:Text('الرئيسية')),
                      NavigationRailDestination(icon:Icon(Icons.search_rounded,color:muted),selectedIcon:Icon(Icons.search_rounded,color:orange),label:Text('اكتشف')),
                      NavigationRailDestination(icon:Icon(Icons.receipt_long_outlined,color:muted),selectedIcon:Icon(Icons.receipt_long_rounded,color:orange),label:Text('طلباتي')),
                      NavigationRailDestination(icon:Icon(Icons.person_outline,color:muted),selectedIcon:Icon(Icons.person_rounded,color:orange),label:Text('حسابي')),
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
  RealtimeChannel? contentChannel;
  @override void initState(){
    super.initState();
    _refreshContent();
    if(NovaSupabase.initialized) contentChannel=NovaSupabase.watchAppContent(_refreshContent);
  }
  @override void dispose(){contentChannel?.unsubscribe();super.dispose();}
  Future<void> _refreshContent() async {
    try{
      final rows=await NovaSupabase.appContent();
      for(final row in rows){
        final k=(row['key']??'').toString();
        if(k.isEmpty)continue;
        appCopy[k]=(row['text_value']??'').toString();
        final image=(row['image_url']??'').toString();
        if(image.isNotEmpty)appMedia[k]=image;
      }
      if(mounted)setState((){});
    }catch(_){}
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
    const SizedBox(height:18),
    Container(
      height:210,
      decoration:BoxDecoration(color:ink,borderRadius:BorderRadius.circular(28),boxShadow:const[BoxShadow(color:Color(0x33000000),blurRadius:22,offset:Offset(0,10))]),
      child:ClipRRect(
        borderRadius:BorderRadius.circular(28),
        child:Stack(fit:StackFit.expand,children:[
          (appMedia['home_hero_image']??'').isNotEmpty
            ? Image.network(appMedia['home_hero_image']!,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Image.asset('assets/nova_rider.webp',fit:BoxFit.cover))
            : Image.asset('assets/nova_rider.webp',fit:BoxFit.cover),
          const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0x22000000),Color(0xD9000000)]))),
          Positioned(right:18,top:18,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(appCopy['home_hero_subtitle']??'كل اللي نفسك فيه…',style:const TextStyle(color:Colors.white70)),
            const SizedBox(height:4),
            Text(appCopy['home_hero_title']??'يوصل لبابك بسرعة',style:const TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w900)),
          ])),
          Positioned(bottom:14,left:14,child:FilledButton(onPressed:widget.onMap,style:FilledButton.styleFrom(backgroundColor:orange,foregroundColor:Colors.white),child:const Text('افتح الخريطة'))),
        ]),
      ),
    ),
    const SizedBox(height:23),Text(appCopy['mood_title']??'اختار إللي على مزاجك',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:11),
    GridView.count(crossAxisCount:4,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),mainAxisSpacing:10,crossAxisSpacing:8,childAspectRatio:.82,children:[Cat('assets/categories/burger_3d.svg','برجر',onAdd:widget.onAdd),Cat('assets/categories/chicken_3d.svg','فراخ',onAdd:widget.onAdd),Cat('assets/categories/pizza_3d.svg','بيتزا',onAdd:widget.onAdd),Cat('assets/categories/dessert_3d.svg','حلويات',onAdd:widget.onAdd),Cat('assets/categories/drinks_3d.svg','مشروبات',onAdd:widget.onAdd),Cat('assets/categories/healthy_3d.svg','صحي',onAdd:widget.onAdd),Cat('assets/categories/breakfast_3d.svg','فطار',onAdd:widget.onAdd),Cat('assets/categories/snacks_3d.svg','سناكس',onAdd:widget.onAdd)]),
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
    const SizedBox(height:22),title('جميع المأكولات والمشروبات',''),const SizedBox(height:12),
    ...data.map((r)=>Padding(padding:const EdgeInsets.only(bottom:14),child:CardR(r:r,onTap:()=>widget.onOpen(r)))),
    const SizedBox(height:4),const Text('المصادر: المنيوز و EGMenus • تحقق من البيانات: سبتمبر 2026',style:TextStyle(color:muted,fontSize:10)),
  ]);
}

Widget title(String a,String b)=>Row(children:[Expanded(child:Text(a,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900))),if(b.isNotEmpty)Text(b,style:const TextStyle(color:orange,fontSize:12,fontWeight:FontWeight.bold))]);

class Cat extends StatelessWidget {
  final String asset,n; final void Function(R,M) onAdd;
  const Cat(this.asset,this.n,{super.key,required this.onAdd});
  @override Widget build(BuildContext c)=>Material(
    color:Colors.transparent,
    child:InkWell(
      onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>CategoryPage(title:n,category:n,onAdd:onAdd))),
      borderRadius:BorderRadius.circular(18),
      child:Container(
        padding:const EdgeInsets.symmetric(vertical:5,horizontal:4),
        decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFF0F0F2)),boxShadow:const[BoxShadow(color:Color(0x12000000),blurRadius:12,offset:Offset(0,5))]),
        child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
          Expanded(child:Padding(padding:const EdgeInsets.fromLTRB(1,0,1,1),child:SvgPicture.asset(asset,fit:BoxFit.contain))),
          const SizedBox(height:2),
          Text(n,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:11))
        ]),
      ),
    ),
  );
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
    final codeText=code??'';
    showDialog(context:c,builder:(_)=>AlertDialog(
      title:Text((offer['title']??'عرض نوفا').toString()),
      content:Text(codeText.isEmpty?(offer['subtitle']??'').toString():'كود العرض: '+codeText+'\n\n'+(offer['subtitle']??'').toString()),
      actions:[
        if(codeText.isNotEmpty)TextButton(onPressed:(){Clipboard.setData(ClipboardData(text:codeText));Navigator.pop(c);snack(c,'تم نسخ الكود '+codeText);},child:const Text('نسخ')),
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
      const SizedBox(height:6),Row(children:[const Icon(Icons.restaurant_menu,size:15,color:muted),const SizedBox(width:5),Expanded(child:Text(r.type,style:const TextStyle(color:muted,fontSize:11)))]),
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
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(owner?'وضع المالك':'وضع العميل',style:const TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.w900)),
          const SizedBox(height:3),Text(owner?'لديك وصول كامل لمركز التحكم':'كل خدمات نوفا متاحة من هنا',style:const TextStyle(color:Colors.white70,fontSize:11)),
        ])),
      ])),
      const SizedBox(height:18),
      st(c,Icons.location_on_outlined,'العناوين والخريطة','موقعك الحالي والأماكن القريبة',widget.onMap),
      st(c,Icons.favorite_border_rounded,'المفضلة',favoriteRestaurants.isEmpty?'لم تحفظ أي مطعم بعد':'${favoriteRestaurants.length} مطعم محفوظ',()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const FavoritesPage()))),
      st(c,Icons.support_agent_rounded,'الدعم الفني','تحدث مع الدعم الفني أو اطلب مسؤولاً',()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const SupportCenterPage()))),
      if(owner) st(c,Icons.dashboard_customize_rounded,'لوحة نوفا','الطلبات والمطاعم والمنيو والعروض والدعم والمحتوى',()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const OwnerStudioPage()))),
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

Future<void> callCourier(BuildContext c, String phone) async {
  final normalized=phone.trim();
  if(normalized.isEmpty)return;
  final uri=Uri(scheme:'tel',path:normalized);
  try{
    final opened=await launchUrl(uri);
    if(!opened&&c.mounted)snack(c,'تعذر فتح تطبيق الاتصال.');
  }catch(_){
    if(c.mounted)snack(c,'تعذر فتح تطبيق الاتصال.');
  }
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
            Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(status=='delivered'?'تم التسليم بنجاح':status=='on_the_way'?'السائق في الطريق إليك':status=='pending'?'في انتظار قبول الطلب':'جاري تجهيز طلبك',style:const TextStyle(fontWeight:FontWeight.w900)),if(['accepted','preparing','ready','picked_up','on_the_way','delivering'].contains(status))const Padding(padding:EdgeInsets.only(top:5),child:Text('مدة التوصيل المتوقعة: 25–40 دقيقة',style:TextStyle(color:muted,fontSize:11,fontWeight:FontWeight.w700)))]),
            const SizedBox(height:10),
            Row(children:List.generate(steps.length,(i)=>Expanded(child:Container(height:7,margin:const EdgeInsets.symmetric(horizontal:2),decoration:BoxDecoration(color:i<=idx?orange:Colors.black12,borderRadius:BorderRadius.circular(8)))))),
            const SizedBox(height:12),
            Text((current['delivery_address']??'عنوان التوصيل').toString(),style:const TextStyle(color:muted,fontSize:11)),
            if(current['courier_phone']!=null && current['courier_phone'].toString().trim().isNotEmpty && status!='pending' && status!='cancelled')
              Padding(
                padding:const EdgeInsets.only(top:14),
                child:Container(
                  padding:const EdgeInsets.all(12),
                  decoration:BoxDecoration(color:orange.withValues(alpha:.08),borderRadius:BorderRadius.circular(18),border:Border.all(color:orange.withValues(alpha:.18))),
                  child:Row(children:[
                    const CircleAvatar(backgroundColor:orange,child:Icon(Icons.person_rounded,color:Colors.white)),
                    const SizedBox(width:10),
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      const Text('مندوبك',style:TextStyle(fontWeight:FontWeight.w900)),
                      Text(current['courier_phone'].toString(),style:const TextStyle(color:muted,fontSize:11)),
                    ])),
                    FilledButton.icon(
                      onPressed:()=>callCourier(c,current['courier_phone'].toString()),
                      style:FilledButton.styleFrom(backgroundColor:orange,minimumSize:const Size(0,44),padding:const EdgeInsets.symmetric(horizontal:14)),
                      icon:const Icon(Icons.call_rounded,size:19),
                      label:const Text('اتصل'),
                    ),
                  ]),
                ),
              ),
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
      case 'سناكس':return h.contains('سناكس')||h.contains('snack')||h.contains('بطاطس')||h.contains('وجبات خفيفة');
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
  Future<void> _load()async{try{conversation=await NovaSupabase.supportConversation();await _refresh();channel=NovaSupabase.watchSupportMessages(conversation!['id'].toString(),_refresh);}catch(e){if(mounted)snack(context,'تعذر فتح الدعم الفني: $e');}if(mounted)setState(()=>loading=false);}
  Future<void> _refresh()async{final id=conversation?['id']?.toString();if(id==null)return;try{final rows=await NovaSupabase.supportMessages(id);if(mounted)setState(()=>messages=rows);await Future.delayed(const Duration(milliseconds:40));if(scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:180),curve:Curves.easeOut);}catch(_){}}
  Future<void> _send()async{final text=input.text.trim();if(text.isEmpty||sending||conversation==null)return;input.clear();setState(()=>sending=true);try{await NovaSupabase.sendSupportMessage(conversation!['id'].toString(),text);if(mounted)setState(()=>messages=[...messages,{'sender_type':'customer','body':text,'image_url':''}]);await Future.delayed(const Duration(milliseconds:40));if(scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:180),curve:Curves.easeOut);}catch(e){if(mounted)snack(context,'تعذر إرسال الرسالة: $e');}if(mounted)setState(()=>sending=false);}
  Future<void> _image()async{if(!imageEnabled||conversation==null)return;final file=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:88,maxWidth:1600);if(file==null)return;try{final url=await NovaSupabase.uploadSupportImage(conversation!['id'].toString(),await file.readAsBytes());await NovaSupabase.sendSupportImage(conversation!['id'].toString(),url);await _refresh();}catch(e){if(mounted)snack(context,'تعذر رفع الصورة: $e');}}
  Widget bubble(Map<String,dynamic> m){final type=(m['sender_type']??'ai').toString(),mine=type=='customer';final image=(m['image_url']??'').toString();return Align(alignment:mine?Alignment.centerLeft:Alignment.centerRight,child:Container(constraints:const BoxConstraints(maxWidth:330),margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:mine?orange:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:mine?Colors.transparent:const Color(0xFFE8E8EA))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if(type!='customer')Padding(padding:const EdgeInsets.only(bottom:4),child:Text(type=='admin'?'مسؤول الدعم':'الدعم الفني',style:TextStyle(fontSize:10,fontWeight:FontWeight.w900,color:mine?Colors.white70:orange))),if(m['body']!=null&&m['body'].toString().isNotEmpty)Text(m['body'].toString(),style:TextStyle(color:mine?Colors.white:ink,fontWeight:FontWeight.w600,height:1.45)),if(image.isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.network(image,width:240,height:180,fit:BoxFit.cover)))])));}
  @override Widget build(BuildContext c){
    if(loading)return const Center(child:CircularProgressIndicator(color:orange));
    final waiting=conversation?['status']=='waiting_admin';
    return Scaffold(
      backgroundColor:const Color(0xFFF7F7F8),
      appBar:AppBar(
        title:const Text('الدعم الفني',style:TextStyle(fontWeight:FontWeight.w900)),
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
                  const Text('الدعم الفني',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:17)),
                  Text(waiting?'تم تحويلك لمسؤول — انتظر القبول هنا':'مساعدتك في الطلبات والمشاكل متاحة هنا',style:const TextStyle(color:Colors.white70,fontSize:11)),
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
                      hintText:waiting?'انتظر قبول مسؤول الدعم...':'اكتب رسالتك...',
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
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text('عميل مجهول #${widget.conversationId.substring(0,6)}',style:const TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:()async{await NovaSupabase.closeSupportConversation(widget.conversationId);if(c.mounted)Navigator.pop(c);},icon:const Icon(Icons.check_circle_outline,color:orange))]),body:Column(children:[Container(margin:const EdgeInsets.all(14),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFFFFF4F0),borderRadius:BorderRadius.circular(18)),child:const Row(children:[Icon(Icons.privacy_tip_outlined,color:orange),SizedBox(width:8),Expanded(child:Text('المحادثة مجهولة للمالك: لا يتم عرض اسم أو بريد العميل هنا.'))])),Expanded(child:ListView.builder(padding:const EdgeInsets.all(14),itemCount:messages.length,itemBuilder:(_,i){final m=messages[i];final mine=m['sender_type']=='admin';final ai=m['sender_type']=='ai';return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(12),constraints:const BoxConstraints(maxWidth:340),decoration:BoxDecoration(color:mine?orange:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFE7E7E9))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(ai?'الدعم الفني':mine?'أنت':'العميل',style:TextStyle(fontSize:9,fontWeight:FontWeight.w900,color:mine?Colors.white70:orange)),const SizedBox(height:4),if((m['body']??'').toString().isNotEmpty)Text(m['body'].toString(),style:TextStyle(color:mine?Colors.white:ink)),if((m['image_url']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.only(top:6),child:Image.network(m['image_url'].toString(),width:220,height:160,fit:BoxFit.cover))])));}),),SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(10,6,10,10),child:Row(children:[Expanded(child:TextField(controller:input,maxLines:4,decoration:InputDecoration(hintText:'اكتب رد المسؤول...',filled:true,fillColor:const Color(0xFFF4F4F5),border:OutlineInputBorder(borderRadius:BorderRadius.circular(20),borderSide:BorderSide.none)))),IconButton(onPressed:sending?null:_send,style:IconButton.styleFrom(backgroundColor:orange,foregroundColor:Colors.white),icon:const Icon(Icons.send_rounded))])))]));
}

class OwnerStudioPage extends NovaOwnerControlCenter { const OwnerStudioPage({super.key}); }

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
                snack(c,'تم إنشاء الطلب الحقيقي #'+_shortId(id)+' بنجاح');
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
