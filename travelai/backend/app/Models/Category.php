<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'icon'];

    public $timestamps = false; // as structured in SQL (created_at only)

    public function places()
    {
        return $this->hasMany(Place::class);
    }
}
