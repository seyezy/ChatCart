<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Report extends Model { protected $fillable=['reporter_user_id','target_type','target_id','category','reason','status','assigned_admin_id']; }
