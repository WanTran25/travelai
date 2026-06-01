<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Favorite;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    public function show($id)
    {
        $user = User::withCount('favorites', 'reviews')
            ->findOrFail($id);

        $favorites = Favorite::where('user_id', $id)
            ->with('place')
            ->get()
            ->pluck('place');

        return response()->json([
            'user' => $user,
            'favorite_places' => $favorites,
        ]);
    }

    public function update(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'name' => 'sometimes|string|max:255',
            'bio' => 'nullable|string|max:1000',
            'avatar' => 'nullable|string|max:500',
            'avatar_file' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:2048',
        ]);

        if ($request->hasFile('avatar_file')) {
            $file = $request->file('avatar_file');
            $filename = 'avatar_' . $user->id . '_' . time() . '.' . $file->getClientOriginalExtension();
            $file->storeAs('public/avatars', $filename);
            $user->avatar = $filename;
        } elseif ($request->has('avatar')) {
            $user->avatar = $request->avatar;
        }

        if ($request->has('name')) {
            $user->name = $request->name;
        }
        if ($request->has('bio')) {
            $user->bio = $request->bio;
        }

        $user->save();

        return response()->json([
            'message' => 'Cập nhật hồ sơ thành công.',
            'user' => $user,
        ]);
    }
}

