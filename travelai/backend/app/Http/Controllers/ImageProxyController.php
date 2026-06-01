<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class ImageProxyController extends Controller
{
    public function proxy(Request $request)
    {
        $url = $request->query('url');
        if (!$url) {
            return response()->json(['error' => 'Missing url parameter'], 400);
        }

        try {
            $response = Http::timeout(10)->get($url);
            return response($response->body())
                ->header('Content-Type', $response->header('Content-Type') ?? 'image/jpeg')
                ->header('Access-Control-Allow-Origin', '*')
                ->header('Cache-Control', 'public, max-age=86400');
        } catch (\Exception $e) {
            return response()->json(['error' => 'Failed to fetch image'], 502);
        }
    }
}
