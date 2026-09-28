import { withSupabase } from "npm:@supabase/server@^1";

const cors={
  "Access-Control-Allow-Origin":"*",
  "Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods":"POST, OPTIONS"
};

const fallback="أنا Nova AI 👋\n\nأنا هنا عشان أساعدك في أي حاجة تخص نوفا ديليفري: الطلبات، المطاعم، المنتجات، السلة، الدفع، التوصيل، التتبع والحساب.\n\nاشرح لي مشكلتك بالتفصيل، وهامشي معاك خطوة بخطوة. ولو احتاجت تدخل من مسؤول، هحوّلك له مباشرة.";

export default {
  fetch: async (req:Request) => {
    if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
    return withSupabase({auth:"user"},async(request,ctx)=>{
      try{
        const key=Deno.env.get("OPENAI_API_KEY");
        const b=await request.json();
        const message=String(b.message??"").trim();
        const conversationId=String(b.conversation_id??"").trim();
        if(!message||!conversationId) throw new Error("message and conversation_id are required");
        const {data:conversation,error:ce}=await ctx.supabase.from("support_conversations").select("id,status,customer_id").eq("id",conversationId).single();
        if(ce||!conversation) throw new Error("Conversation not found");
        if(conversation.status!=="ai") return new Response(JSON.stringify({reply:"المحادثة الآن مع مسؤول الدعم.",handoff:false,configured:Boolean(key)}),{status:200,headers:{...cors,"Content-Type":"application/json"}});

        const [{data:rows},{data:restaurants},{data:offers},{data:orders},{data:content}] = await Promise.all([
          ctx.supabase.from("support_messages").select("sender_type,body").eq("conversation_id",conversationId).order("created_at",{ascending:true}).limit(30),
          ctx.supabaseAdmin.from("restaurants").select("id,name,description,rating,is_active").eq("is_active",true).order("name").limit(80),
          ctx.supabaseAdmin.from("offers").select("title,subtitle,is_active").eq("is_active",true).order("sort_order").limit(40),
          ctx.supabase.from("orders").select("id,status,total,restaurant_name,created_at").eq("customer_id",conversation.customer_id).order("created_at",{ascending:false}).limit(8),
          ctx.supabaseAdmin.from("app_content").select("key,text_value").order("key").limit(50),
        ]);

        const restaurantIds=(restaurants??[]).map((r:any)=>r.id).filter(Boolean);
        let menu:any[]=[];
        if(restaurantIds.length){
          const {data}=await ctx.supabaseAdmin.from("menu_items").select("restaurant_id,name,description,price,is_available").in("restaurant_id",restaurantIds).eq("is_available",true).order("restaurant_id").limit(300);
          menu=data??[];
        }
        const restaurantText=(restaurants??[]).map((r:any)=>{
          const items=menu.filter((m:any)=>String(m.restaurant_id)===String(r.id)).slice(0,18);
          const menuText=items.map((m:any)=>String(m.name)+" ("+String(m.price)+" ج.م)"+(m.description?" — "+String(m.description):"")).join(" | ");
          return "- "+String(r.name)+": "+String(r.description??"")+(menuText?" | المنيو: "+menuText:"");
        }).join("\n");
        const appText=(content??[]).filter((x:any)=>x.text_value).map((x:any)=>String(x.key)+": "+String(x.text_value)).join("\n");
        const offerText=(offers??[]).map((x:any)=>"- "+String(x.title)+": "+String(x.subtitle??"")).join("\n");
        const orderText=(orders??[]).map((x:any)=>"- #"+String(x.id).slice(0,8)+" • "+String(x.restaurant_name??"مطعم")+" • "+String(x.status)+" • "+String(x.total??0)+" ج.م").join("\n");
        const history=(rows??[]).map((m:any)=>({role:m.sender_type==="customer"?"user":"assistant",content:String(m.body??"")}));

        let reply=fallback;
        let handoff=/مسؤول|الإدارة|موظف|بشر|دعم فني|خدمة العملاء|اكلم حد|عايز حد|كلمني حد|شكوى رسمية/i.test(message);
        if(key){
          const system="أنت Nova AI، المساعد الرسمي والذكي لتطبيق نوفا ديليفري.\nتحدث بالعربية المصرية بشكل راقٍ، دافئ، واضح ومنظم. استخدم عناوين قصيرة ونقاط عند الحاجة، ولا تكتب فقرات طويلة بلا تنظيم.\nأنت تعرف التطبيق والبيانات الحالية الموجودة في السياق أدناه، ويمكنك شرح طريقة استخدام التطبيق، حالة الطلبات، المطاعم، المنتجات، الأسعار، العروض، السلة، الدفع، التوصيل، التتبع والحساب.\nاعتمد على البيانات المرفقة ولا تخترع مطعماً أو منتجاً أو سعراً أو حالة طلب. إذا لم تجد المعلومة أو كانت المشكلة تحتاج صلاحية تنفيذية/تدخل بشري، ابدأ الرد بـ [HANDOFF].\nلا تطلب كلمة المرور أو مفاتيح API أو أي سر. لا تدّعي أنك نفذت إجراءً لم تنفذه.\nإذا كانت المشكلة قابلة للحل، أعطِ خطوات عملية مرتبة. إذا كان هناك أكثر من احتمال، اسأل سؤالاً واحداً واضحاً في النهاية.\nإذا طلب العميل مسؤولاً، استخدم [HANDOFF].\n\nبيانات التطبيق:\n"+(appText||"نوفا ديليفري: تطبيق لطلب الطعام وتتبع الطلبات والتواصل مع الدعم.")+"\n\nالمطاعم والمنتجات المتاحة حالياً:\n"+(restaurantText||"لا توجد بيانات كتالوج متاحة حالياً.")+"\n\nالعروض الحالية:\n"+(offerText||"لا توجد عروض متاحة حالياً.")+"\n\nآخر طلبات العميل:\n"+(orderText||"لا توجد طلبات سابقة متاحة.");
          const rr=await fetch("https://api.openai.com/v1/responses",{method:"POST",headers:{"Authorization":"Bearer "+key,"Content-Type":"application/json"},body:JSON.stringify({model:"gpt-5.6-luna",input:[{role:"system",content:system},...history],max_output_tokens:900})});
          const d=await rr.json();
          if(rr.ok){
            reply=String(d.output_text??reply).trim()||reply;
            handoff=handoff||reply.startsWith("[HANDOFF]");
            reply=reply.replace(/^\[HANDOFF\]\s*/i,"").trim();
          }
        }
        if(handoff) reply="تمام، فهمت المشكلة. 🤝\n\nحوّلت المحادثة لمسؤول الدعم عشان يتابعها معاك بشكل مباشر. انتظر قبول المسؤول هنا، وبمجرد ما يقبل هتقدر تكملوا المحادثة وترفع صورة للمشكلة لو محتاج.";
        const ins=await ctx.supabaseAdmin.from("support_messages").insert({conversation_id:conversationId,sender_type:"ai",body:reply});
        if(ins.error) throw ins.error;
        if(handoff) await ctx.supabaseAdmin.from("support_conversations").update({status:"waiting_admin",assigned_admin_id:null,updated_at:new Date().toISOString()}).eq("id",conversationId);
        return new Response(JSON.stringify({reply,handoff,configured:Boolean(key)}),{status:200,headers:{...cors,"Content-Type":"application/json"}});
      }catch(e){
        console.error(e);
        return new Response(JSON.stringify({reply:"حصل عطل مؤقت في المساعد. لو محتاج تدخل مسؤول اكتب: «عايز مسؤول».",handoff:false,configured:Boolean(Deno.env.get("OPENAI_API_KEY"))}),{status:200,headers:{...cors,"Content-Type":"application/json"}});
      }
    })(req);
  }
};