<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Place extends Model
{
    use HasFactory;

    protected $fillable = [
        'category_id',
        'name',
        'description',
        'address',
        'latitude',
        'longitude',
        'image_url',
        'rating_avg',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'rating_avg' => 'float',
    ];

    public $timestamps = false;

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function reviews()
    {
        return $this->hasMany(Review::class);
    }

    public function favoritedByUsers()
    {
        return $this->belongsToMany(User::class, 'favorites', 'place_id', 'user_id');
    }
}
