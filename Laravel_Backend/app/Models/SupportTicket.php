<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class SupportTicket extends Model { protected $fillable=['ticket_no','user_id','subject','category','priority','status']; }
