<?php

namespace App\Http\Controllers;

use App\Models\Message;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MessageController extends Controller
{
    public function conversations(Request $request)
    {
        $userId = $request->user()->id;

        $userIds = Message::where('sender_id', $userId)
            ->orWhere('receiver_id', $userId)
            ->selectRaw('DISTINCT CASE WHEN sender_id = ? THEN receiver_id ELSE sender_id END AS user_id', [$userId])
            ->pluck('user_id');

        $users = User::whereIn('id', $userIds)->get()->map(function ($user) use ($userId) {
            $lastMessage = Message::where(function ($q) use ($userId, $user) {
                $q->where('sender_id', $userId)->where('receiver_id', $user->id);
            })->orWhere(function ($q) use ($userId, $user) {
                $q->where('sender_id', $user->id)->where('receiver_id', $userId);
            })->orderBy('created_at', 'desc')->first();

            return [
                'user' => $user,
                'last_message' => $lastMessage,
                'unread_count' => Message::where('sender_id', $user->id)
                    ->where('receiver_id', $userId)
                    ->where('created_at', '>', $user->last_read_at ?? '1970-01-01')
                    ->count(),
            ];
        });

        $users = $users->sortByDesc(function ($item) {
            return $item['last_message']?->created_at?->timestamp ?? 0;
        })->values();

        return response()->json($users);
    }

    public function messages(Request $request, $userId)
    {
        $currentUserId = $request->user()->id;

        $messages = Message::where(function ($q) use ($currentUserId, $userId) {
            $q->where('sender_id', $currentUserId)->where('receiver_id', $userId);
        })->orWhere(function ($q) use ($currentUserId, $userId) {
            $q->where('sender_id', $userId)->where('receiver_id', $currentUserId);
        })->with('sender:id,name,avatar')->orderBy('created_at', 'asc')->get();

        return response()->json($messages);
    }

    public function store(Request $request)
    {
        $request->validate([
            'receiver_id' => 'required|exists:users,id',
            'content' => 'required|string|max:5000',
        ]);

        $message = Message::create([
            'sender_id' => $request->user()->id,
            'receiver_id' => $request->receiver_id,
            'content' => $request->content,
        ]);

        $message->load('sender:id,name,avatar');

        return response()->json($message, 201);
    }

    public function destroy(Request $request, $id)
    {
        $message = Message::findOrFail($id);

        if ($message->sender_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $message->delete();
        return response()->json(['message' => 'Message deleted.']);
    }

    public function availableUsers(Request $request)
    {
        $users = User::where('id', '!=', $request->user()->id)
            ->where('is_active', true)
            ->select('id', 'name', 'avatar')
            ->get();

        return response()->json($users);
    }
}
