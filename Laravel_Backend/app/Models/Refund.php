<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Refund extends Model { protected $fillable=['order_id','transaction_id','amount','reason','status','reviewed_by']; }
