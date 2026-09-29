<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class SupportMessage extends Model { protected $fillable=['support_ticket_id','sender_type','sender_id','message','attachments']; protected $casts=['attachments'=>'array']; }
