<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Device extends Model { protected $fillable=['user_id','device_id','platform','fcm_token','revoked_at','last_seen_at']; protected $casts=['revoked_at'=>'datetime','last_seen_at'=>'datetime']; }
