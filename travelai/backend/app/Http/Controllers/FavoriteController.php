<?php

namespace App\Http\Controllers;

use App\Models\Favorite;
use Illuminate\Http\Request;

class FavoriteController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $favorites = $user->favoritePlaces()->with('category')->get();
        
        return response()->json($favorites);
    }

    public function store(Request $request, $place_id)
    {
        $user = $request->user();
        
        $favorite = Favorite::firstOrCreate([
            'user_id' => $user->id,
            'place_id' => $place_id
        ]);

        return response()->json([
            'message' => 'Đã thêm vào danh sách yêu thích.',
            'favorite' => $favorite
        ], 201);
    }

    public function destroy(Request $request, $place_id)
    {
        $user = $request->user();
        
        Favorite::where('user_id', $user->id)
            ->where('place_id', $place_id)
            ->delete();

        return response()->json([
            'message' => 'Đã xóa khỏi danh sách yêu thích.'
        ]);
    }
}
