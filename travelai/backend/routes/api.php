<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\PlaceController;
use App\Http\Controllers\FavoriteController;
use App\Http\Controllers\ReviewController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\AiSuggestController;
use App\Http\Controllers\ImageProxyController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\CategoryController as AdminCategoryController;
use App\Http\Controllers\Admin\PlaceController as AdminPlaceController;
use App\Http\Controllers\Admin\UserController as AdminUserController;
use App\Http\Controllers\Admin\ReviewController as AdminReviewController;
use App\Http\Controllers\Admin\AiLogController as AdminAiLogController;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

/*
|--------------------------------------------------------------------------
| API Routes - TravelAI App Connections
|--------------------------------------------------------------------------
*/

// Public Authentication Routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Public Exploration Routes
Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/places', [PlaceController::class, 'index']);
Route::get('/places/{id}', [PlaceController::class, 'show']);
Route::get('/reviews/place/{place_id}', [ReviewController::class, 'showByPlace']);

// Proxy external images to avoid CORS
Route::get('/image-proxy', [ImageProxyController::class, 'proxy']);

// Serve avatar images with CORS headers
Route::get('/avatars/{filename}', function ($filename) {
    $path = Storage::disk('public')->path('avatars/' . $filename);
    if (!file_exists($path)) abort(404);
    return response()->file($path);
})->where('filename', '.*');

// Authenticated Routes (Requires Laravel Sanctum)
Route::middleware('auth:sanctum')->group(function () {
    // Current User Session
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'user']);

    // Favorites Management
    Route::get('/favorites', [FavoriteController::class, 'index']);
    Route::post('/favorites/{place_id}', [FavoriteController::class, 'store']);
    Route::delete('/favorites/{place_id}', [FavoriteController::class, 'destroy']);

    // Review Submission
    Route::post('/reviews', [ReviewController::class, 'store']);
    Route::post('/reviews/{review_id}/react', [ReviewController::class, 'react']);

    // Profile
    Route::get('/profile/{id}', [ProfileController::class, 'show']);
    Route::match(['put', 'post'], '/profile', [ProfileController::class, 'update']);

    // Smart Travel Assistant AI Suggestion
    Route::post('/ai/suggest', [AiSuggestController::class, 'suggest']);

    // Admin Routes (requires auth:sanctum + admin)
    Route::middleware(\App\Http\Middleware\AdminMiddleware::class)->prefix('admin')->group(function () {
        Route::get('/dashboard', [DashboardController::class, 'index']);

        Route::get('/categories', [AdminCategoryController::class, 'index']);
        Route::post('/categories', [AdminCategoryController::class, 'store']);
        Route::get('/categories/{id}', [AdminCategoryController::class, 'show']);
        Route::put('/categories/{id}', [AdminCategoryController::class, 'update']);
        Route::delete('/categories/{id}', [AdminCategoryController::class, 'destroy']);

        Route::get('/places', [AdminPlaceController::class, 'index']);
        Route::post('/places', [AdminPlaceController::class, 'store']);
        Route::get('/places/{id}', [AdminPlaceController::class, 'show']);
        Route::put('/places/{id}', [AdminPlaceController::class, 'update']);
        Route::delete('/places/{id}', [AdminPlaceController::class, 'destroy']);

        Route::get('/users', [AdminUserController::class, 'index']);
        Route::post('/users', [AdminUserController::class, 'store']);
        Route::get('/users/{id}', [AdminUserController::class, 'show']);
        Route::post('/users/{id}/toggle-active', [AdminUserController::class, 'toggleActive']);
        Route::post('/users/{id}/toggle-admin', [AdminUserController::class, 'toggleAdmin']);
        Route::delete('/users/{id}', [AdminUserController::class, 'destroy']);

        Route::get('/reviews', [AdminReviewController::class, 'index']);
        Route::delete('/reviews/{id}', [AdminReviewController::class, 'destroy']);

        Route::get('/ai-logs', [AdminAiLogController::class, 'index']);
        Route::get('/ai-logs/{id}', [AdminAiLogController::class, 'show']);
    });
});
