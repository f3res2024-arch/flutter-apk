import { withSupabase } from "npm:@supabase/server@^1";
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
export default { fetch: async (req:Request) => {
 if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
 return withSupabase({auth:"user"},async(request,ctx)=>{
  try{
   const key=Deno.env.get("OPENAI_API_KEY"); const b=await request.json();
   const message=String(b.message??"").trim(), conversationId=String(b.conversation_id??"").trim();
   if(!message||!conversationId) throw new Error("message and conversation_id are required");
   const {data:conversation,error:ce}=await ctx.supabase.from("support_conversations").select("id,status").eq("id",conversationId).single();
   if(ce||!conversation) throw new Error("Conversation not found");
   const {data:rows}=await ctx.supabase.from("support_messages").select("sender_type,body").eq("conversation_id",conversationId).order("created_at",{ascending:true}).limit(24);
   const history=(rows??[]).map((m:any)=>({role:m.sender_type==="customer"?"user":"assistant",content:String(m.body??"")}));
   let reply="أنا جاهز أساعدك. اشرح لي المشكلة بالتفصيل وسأمشي معك خطوة بخطوة.";
   let handoff=/مسؤول|الإدارة|موظف|بشر|دعم فني|خدمة العملاء|اكلم حد|عايز حد|كلمني حد/i.test(message);
   if(key){
    const system="أنت Nova AI، مساعد الدعم الرسمي لتطبيق نوفا ديليفري. تحدث بالعربية المصرية بشكل محترم وعملي. ساعد في الطلبات والمطاعم والسلة والدفع والحساب والتوصيل والتتبع والعروض والمشاكل التقنية. لا تطلب كلمة المرور أو الأسرار. لا تدّعي تنفيذ إجراء لم تنفذه. إذا طلب العميل مسؤولاً أو كانت المشكلة تحتاج تدخلاً بشرياً ابدأ الرد بـ [HANDOFF].";
    const rr=await fetch("https://api.openai.com/v1/responses",{method:"POST",headers:{"Authorization":"Bearer "+key,"Content-Type":"application/json"},body:JSON.stringify({model:"gpt-5.6-luna",input:[{role:"system",content:system},...history],max_output_tokens:700})});
    const d=await rr.json(); if(rr.ok){reply=String(d.output_text??reply).trim()||reply;handoff=handoff||reply.startsWith("[HANDOFF]");reply=reply.replace(/^\[HANDOFF\]\s*/i,"");}
   }
   if(handoff) reply="تمام، فهمت إنك محتاج مسؤول. تم تحويل المحادثة للدعم، انتظر مسؤول يرد عليك هنا. بعد ما المسؤول يتواصل معك هتقدر ترفع صورة لو محتاج تشرح المشكلة بشكل أوضح.";
   const ins=await ctx.supabaseAdmin.from("support_messages").insert({conversation_id:conversationId,sender_type:"ai",body:reply}); if(ins.error) throw ins.error;
   if(handoff) await ctx.supabaseAdmin.from("support_conversations").update({status:"waiting_admin",updated_at:new Date().toISOString()}).eq("id",conversationId);
   return new Response(JSON.stringify({reply,handoff,configured:Boolean(key)}),{status:200,headers:{...cors,"Content-Type":"application/json"}});
  }catch(e){console.error(e);return new Response(JSON.stringify({reply:"حصل عطل مؤقت في المساعد. لو محتاج مسؤول اكتب «عايز مسؤول».",handoff:false,configured:false}),{status:200,headers:{...cors,"Content-Type":"application/json"}});}
 })(req);
}};
