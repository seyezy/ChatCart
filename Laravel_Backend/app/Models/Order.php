<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Order extends Model { protected $fillable=['order_no','buyer_user_id','subtotal','commission','total','currency','payment_method','payment_status','status','delivery_address']; protected $casts=['delivery_address'=>'array']; }
