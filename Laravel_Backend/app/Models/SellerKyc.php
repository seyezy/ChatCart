<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class SellerKyc extends Model { protected $fillable=['user_id','legal_name','business_name','country','document_type','document_number','document_urls','selfie_url','status','review_notes']; protected $casts=['document_urls'=>'array']; }
