<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Transaction extends Model { protected $fillable=['order_id','reference','gateway','amount','currency','type','status','payload']; protected $casts=['payload'=>'array']; }
