<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AiSuggestionsLog;

class AiLogController extends Controller
{
    public function index()
    {
        return response()->json(
            AiSuggestionsLog::with('user:id,name')->latest()->get()
        );
    }

    public function show($id)
    {
        return response()->json(AiSuggestionsLog::with('user:id,name')->findOrFail($id));
    }
}
