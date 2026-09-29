<?php
namespace App\Http\Controllers\Api\V1;
use App\Http\Controllers\Controller; use App\Models\SellerKyc; use Illuminate\Http\Request;
class KycController extends Controller {
 public function show(Request $r){$u=$r->attributes->get('app_user');return response()->json(['ok'=>true,'kyc'=>SellerKyc::where('user_id',$u->id)->latest()->first()]);}
 public function store(Request $r){$d=$r->validate(['legal_name'=>'required|string|max:150','business_name'=>'nullable|string|max:150','country'=>'required|string|max:80','document_type'=>'required|string|max:80','document_number'=>'required|string|max:150','document_urls'=>'required|array|min:1','document_urls.*'=>'string','selfie_url'=>'required|string']);$u=$r->attributes->get('app_user');$x=SellerKyc::updateOrCreate(['user_id'=>$u->id],$d+['status'=>'pending']);return response()->json(['ok'=>true,'kyc'=>$x],201);}
}
