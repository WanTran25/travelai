<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AiSuggestionsLog extends Model
{
    protected $table = 'ai_suggestions_log';

    protected $fillable = [
        'user_id',
        'user_prompt',
        'ai_response',
    ];

    protected $casts = [
        'ai_response' => 'array',
    ];

    public $timestamps = false;
}
