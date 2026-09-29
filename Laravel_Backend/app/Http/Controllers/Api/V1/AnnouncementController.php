<?php
namespace App\Http\Controllers\Api\V1; use App\Http\Controllers\Controller; use App\Models\Announcement; use Illuminate\Http\Request;
class AnnouncementController extends Controller { public function index(Request $r){$placement=$r->query('placement','global');$q=Announcement::where('status','published')->whereIn('placement',['global',$placement])->where(fn($x)=>$x->whereNull('starts_at')->orWhere('starts_at','<=',now()))->where(fn($x)=>$x->whereNull('ends_at')->orWhere('ends_at','>=',now()));return response()->json(['ok'=>true,'announcements'=>$q->latest()->get()]);} }
