<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class AuditLog extends Model { protected $fillable=['admin_id','action','entity_type','entity_id','metadata','ip_address']; protected $casts=['metadata'=>'array']; }
