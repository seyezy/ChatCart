<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class AppUser extends Model { protected $fillable=['firebase_uid','email','phone','display_name','status']; }
