<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class MarketplaceCategory extends Model { protected $table='marketplace_categories'; protected $fillable=['name','slug','status','sort_order']; }
