<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Place;
use App\Models\Review;
use App\Models\User;
use App\Models\AiSuggestionsLog;

class DashboardController extends Controller
{
    public function index()
    {
        $placesByCategory = Category::withCount('places')->get(['id', 'name']);
        $ratingDistribution = [
            '1' => Review::where('rating', 1)->count(),
            '2' => Review::where('rating', 2)->count(),
            '3' => Review::where('rating', 3)->count(),
            '4' => Review::where('rating', 4)->count(),
            '5' => Review::where('rating', 5)->count(),
        ];

        return response()->json([
            'total_users' => User::count(),
            'total_places' => Place::count(),
            'total_categories' => Category::count(),
            'total_reviews' => Review::count(),
            'total_ai_logs' => AiSuggestionsLog::count(),
            'recent_users' => User::latest()->take(5)->get(['id', 'name', 'email', 'avatar', 'created_at']),
            'recent_reviews' => Review::with('user:id,name')->latest()->take(5)->get(),
            'top_places' => Place::orderByDesc('rating_avg')->take(5)->get(['id', 'name', 'rating_avg']),
            'places_by_category' => $placesByCategory,
            'rating_distribution' => $ratingDistribution,
        ]);
    }
}
