<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Place;
use Illuminate\Http\Request;

class PlaceController extends Controller
{
    public function index()
    {
        return response()->json(Place::with('category:id,name')->get());
    }

    public function store(Request $request)
    {
        $request->validate([
            'category_id' => 'required|exists:categories,id',
            'name' => 'required|string|max:255',
            'description' => 'required|string',
            'address' => 'required|string',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'image_url' => 'nullable|string|max:500',
        ]);

        $data = $request->except(['rating_avg']);
        $data['rating_avg'] = 0;
        $place = Place::create($data);
        return response()->json($place, 201);
    }

    public function show($id)
    {
        return response()->json(Place::with('category:id,name')->findOrFail($id));
    }

    public function update(Request $request, $id)
    {
        $place = Place::findOrFail($id);
        $data = $request->except(['rating_avg']);
        $place->update($data);
        return response()->json($place);
    }

    public function destroy($id)
    {
        Place::findOrFail($id)->delete();
        return response()->json(['message' => 'Deleted successfully.']);
    }
}
