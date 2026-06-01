<?php

namespace App\Http\Controllers;

use App\Models\Place;
use App\Models\Review;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'place_id' => 'required|exists:places,id',
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'required|string|max:1000',
        ]);

        $user = $request->user();

        $review = Review::create([
            'user_id' => $user->id,
            'place_id' => $request->place_id,
            'rating' => $request->rating,
            'comment' => $request->comment,
        ]);

        $review->load('user');

        $avg = Review::where('place_id', $request->place_id)->avg('rating');
        Place::where('id', $request->place_id)->update(['rating_avg' => round($avg, 1)]);

        return response()->json([
            'message' => 'Đã gửi đánh giá thành công.',
            'review' => $review
        ], 201);
    }

    public function showByPlace($place_id)
    {
        $reviews = Review::where('place_id', $place_id)
            ->with('user')
            ->withCount('reactions')
            ->orderBy('id', 'desc')
            ->get();

        $user = request()->user();
        $userId = $user?->id;

        $data = $reviews->map(function ($review) use ($userId) {
            $item = $review->toArray();
            $item['user_avatar'] = $review->user?->avatar_url;
            $reactions = $review->reactions()
                ->selectRaw('reaction, count(*) as count')
                ->groupBy('reaction')
                ->pluck('count', 'reaction');
            $item['reaction_counts'] = $reactions->isNotEmpty() ? $reactions->toArray() : (object)[];
            $item['user_reaction'] = $userId
                ? $review->reactions()->where('user_id', $userId)->value('reaction')
                : null;
            return $item;
        });

        return response()->json($data);
    }

    public function react(Request $request, $review_id)
    {
        $request->validate([
            'reaction' => 'required|string|in:like,love,laugh,cry,angry',
        ]);

        $user = $request->user();
        $review = Review::findOrFail($review_id);

        $existing = \App\Models\ReviewReaction::where('user_id', $user->id)
            ->where('review_id', $review_id)
            ->first();

        if ($existing) {
            if ($existing->reaction === $request->reaction) {
                $existing->delete();
                return response()->json(['message' => 'Bỏ phản ứng.', 'reaction' => null]);
            }
            $existing->update(['reaction' => $request->reaction]);
            return response()->json(['message' => 'Đã đổi phản ứng.', 'reaction' => $request->reaction]);
        }

        \App\Models\ReviewReaction::create([
            'user_id' => $user->id,
            'review_id' => $review_id,
            'reaction' => $request->reaction,
        ]);

        return response()->json(['message' => 'Đã phản ứng.', 'reaction' => $request->reaction], 201);
    }
}
