<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Product extends Model { protected $fillable=['seller_user_id','category_id','title','description','price','currency','stock','image_urls','status']; protected $casts=['image_urls'=>'array']; }
