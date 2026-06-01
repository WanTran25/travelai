<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Place;
use App\Models\Review;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    public function index()
    {
        return response()->json(
            Review::with(['user:id,name', 'place:id,name'])->latest()->get()
        );
    }

    public function destroy($id)
    {
        $review = Review::findOrFail($id);
        $placeId = $review->place_id;
        $review->delete();

        $avg = Review::where('place_id', $placeId)->avg('rating');
        Place::where('id', $placeId)->update(['rating_avg' => $avg ? round($avg, 1) : 0]);

        return response()->json(['message' => 'Review deleted.']);
    }
}
