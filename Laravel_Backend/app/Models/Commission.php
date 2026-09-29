<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Commission extends Model { protected $fillable=['order_id','seller_user_id','rate','amount','status']; }
