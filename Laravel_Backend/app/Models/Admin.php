<?php
namespace App\Models;
use Illuminate\Foundation\Auth\User as Authenticatable;
class Admin extends Authenticatable { protected $fillable=['name','email','password','is_active']; protected $hidden=['password']; protected $casts=['password'=>'hashed']; public function roles(){return $this->belongsToMany(Role::class);} public function hasPermission(string $slug):bool{return $this->roles()->whereHas('permissions',fn($q)=>$q->where('slug',$slug))->exists();} }
