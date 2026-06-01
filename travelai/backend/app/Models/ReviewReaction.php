<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ReviewReaction extends Model
{
    protected $fillable = ['user_id', 'review_id', 'reaction'];

    public $timestamps = false;

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function review()
    {
        return $this->belongsTo(Review::class);
    }
}
