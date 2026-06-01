<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $query = User::select(['id', 'name', 'email', 'avatar', 'is_admin', 'is_active', 'created_at']);
        if ($search = $request->query('search')) {
            $query->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
        }
        return response()->json($query->get());
    }

    public function show($id)
    {
        return response()->json(User::findOrFail($id));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
            'is_admin' => 'boolean',
        ]);

        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
            'is_admin' => $data['is_admin'] ?? false,
        ]);

        return response()->json($user, 201);
    }

    public function toggleActive($id)
    {
        $user = User::findOrFail($id);
        $user->is_active = !$user->is_active;
        $user->save();

        if (!$user->is_active) {
            $user->tokens()->delete();
        }

        return response()->json(['message' => 'User status updated.', 'is_active' => $user->is_active]);
    }

    public function toggleAdmin($id)
    {
        if ($id == request()->user()->id) {
            return response()->json(['message' => 'Không thể tự huỷ quyền Admin của chính mình.'], 400);
        }
        $user = User::findOrFail($id);
        $user->is_admin = !$user->is_admin;
        $user->save();
        return response()->json(['message' => 'Admin status updated.', 'is_admin' => $user->is_admin]);
    }

    public function destroy($id)
    {
        if ($id == request()->user()->id) {
            return response()->json(['message' => 'Cannot delete yourself.'], 400);
        }
        User::findOrFail($id)->delete();
        return response()->json(['message' => 'User deleted.']);
    }
}
