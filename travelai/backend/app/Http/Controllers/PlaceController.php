<?php

namespace App\Http\Controllers;

use App\Models\Place;
use Illuminate\Http\Request;

class PlaceController extends Controller
{
    public function index(Request $request)
    {
        $query = Place::query();

        if ($request->has('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        $places = $query->with('category')->get();
        return response()->json($places);
    }

    public function show($id)
    {
        $place = Place::with(['category', 'reviews.user'])->findOrFail($id);
        
        // Calculate average review score
        $reviewsCount = $place->reviews()->count();
        $ratingAvg = $reviewsCount > 0 ? round($place->reviews()->avg('rating'), 1) : $place->rating_avg;
        
        $place->calculated_rating_avg = $ratingAvg;

        return response()->json($place);
    }
}
