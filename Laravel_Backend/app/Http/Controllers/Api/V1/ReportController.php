<?php
namespace App\Http\Controllers\Api\V1;
use App\Http\Controllers\Controller;
use App\Models\Report;
use Illuminate\Http\Request;
class ReportController extends Controller {
 public function user(Request $r){$d=$r->validate(['reported_uid'=>'required|string','category'=>'required|string|max:80','reason'=>'nullable|string|max:2000']);$u=$r->attributes->get('app_user');$x=Report::create(['reporter_user_id'=>$u->id,'target_type'=>'user','target_id'=>$d['reported_uid'],'category'=>$d['category'],'reason'=>$d['reason']??null,'status'=>'open']);return response()->json(['ok'=>true,'report'=>$x],201);}
 public function message(Request $r){$d=$r->validate(['conversation_id'=>'required|string','message_id'=>'required|string','category'=>'required|string|max:80','reason'=>'nullable|string|max:2000']);$u=$r->attributes->get('app_user');$x=Report::create(['reporter_user_id'=>$u->id,'target_type'=>'message','target_id'=>$d['conversation_id'].':'.$d['message_id'],'category'=>$d['category'],'reason'=>$d['reason']??null,'status'=>'open']);return response()->json(['ok'=>true,'report'=>$x],201);}
}
