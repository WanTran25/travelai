<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Category;
use App\Models\Place;
use App\Models\Review;

// Test các chức năng admin (quản lý danh mục, địa điểm, người dùng, đánh giá)
class AdminTest extends TestCase
{
    private User $admin;
    private User $normalUser;
    private string $adminToken;
    private string $userToken;

    protected function setUp(): void
    {
        parent::setUp();

        $this->admin = User::create([
            'name' => 'Admin',
            'email' => 'admin@test.com',
            'password' => bcrypt('123456'),
            'is_admin' => true,
        ]);
        $this->adminToken = $this->admin->createToken('auth_token')->plainTextToken;

        $this->normalUser = User::create([
            'name' => 'User',
            'email' => 'user@test.com',
            'password' => bcrypt('123456'),
        ]);
        $this->userToken = $this->normalUser->createToken('auth_token')->plainTextToken;

        // Tao du lieu mau
        Category::create(['id' => 1, 'name' => 'Am thuc', 'icon' => 'restaurant']);
        Place::create([
            'id' => 1, 'category_id' => 1, 'name' => 'Pho Bo',
            'description' => 'Ngon', 'address' => 'Ha Noi',
            'latitude' => 21.0, 'longitude' => 105.0,
        ]);
    }

    private function adminHeaders(): array
    {
        return ['Authorization' => "Bearer $this->adminToken"];
    }

    private function userHeaders(): array
    {
        return ['Authorization' => "Bearer $this->userToken"];
    }

    // ===================== DASHBOARD =====================

    public function test_admin_xem_dashboard()
    {
        $response = $this->withHeaders($this->adminHeaders())
            ->getJson('/api/admin/dashboard');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'total_users', 'total_places', 'total_categories', 'total_reviews',
            ]);
    }

    public function test_user_thuong_khong_xem_duoc_dashboard()
    {
        $response = $this->withHeaders($this->userHeaders())
            ->getJson('/api/admin/dashboard');

        $response->assertStatus(403);
    }

    // ===================== CATEGORIES =====================

    public function test_admin_tao_danh_muc()
    {
        $response = $this->withHeaders($this->adminHeaders())
            ->postJson('/api/admin/categories', [
                'name' => 'Giai tri',
                'icon' => 'gamepad',
            ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('categories', ['name' => 'Giai tri']);
    }

    public function test_admin_sua_danh_muc()
    {
        $response = $this->withHeaders($this->adminHeaders())
            ->putJson('/api/admin/categories/1', [
                'name' => 'Am thuc Viet Nam',
            ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('categories', ['name' => 'Am thuc Viet Nam']);
    }

    public function test_admin_xoa_danh_muc()
    {
        $response = $this->withHeaders($this->adminHeaders())
            ->deleteJson('/api/admin/categories/1');

        $response->assertStatus(200);
        $this->assertDatabaseMissing('categories', ['id' => 1]);
    }

    // ===================== PLACES =====================

    public function test_admin_tao_dia_diem()
    {
        $response = $this->withHeaders($this->adminHeaders())
            ->postJson('/api/admin/places', [
                'category_id' => 1,
                'name' => 'Bun Bo Hue',
                'description' => 'Mon ngon mien Trung',
                'address' => 'Hue',
                'latitude' => 16.0,
                'longitude' => 107.0,
                'image_url' => '',
            ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('places', ['name' => 'Bun Bo Hue']);
    }

    public function test_admin_sua_dia_diem()
    {
        $response = $this->withHeaders($this->adminHeaders())
            ->putJson('/api/admin/places/1', [
                'name' => 'Pho Bo Ha Noi Updated',
            ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('places', ['name' => 'Pho Bo Ha Noi Updated']);
    }

    public function test_admin_xoa_dia_diem()
    {
        $response = $this->withHeaders($this->adminHeaders())
            ->deleteJson('/api/admin/places/1');

        $response->assertStatus(200);
        $this->assertDatabaseMissing('places', ['id' => 1]);
    }

    // ===================== USERS =====================

    public function test_admin_xem_danh_sach_nguoi_dung()
    {
        $response = $this->withHeaders($this->adminHeaders())
            ->getJson('/api/admin/users');

        $response->assertStatus(200);
        $response->assertJsonFragment(['email' => 'admin@test.com']);
        $response->assertJsonFragment(['email' => 'user@test.com']);
    }

    public function test_admin_khoa_mo_tai_khoan()
    {
        $response = $this->withHeaders($this->adminHeaders())
            ->postJson("/api/admin/users/{$this->normalUser->id}/toggle-active");

        $response->assertStatus(200);
        $response->assertJsonFragment(['is_active' => false]);
    }

    public function test_admin_xoa_nguoi_dung()
    {
        $response = $this->withHeaders($this->adminHeaders())
            ->deleteJson("/api/admin/users/{$this->normalUser->id}");

        $response->assertStatus(200);
        $this->assertDatabaseMissing('users', ['id' => $this->normalUser->id]);
    }

    // ===================== REVIEWS =====================

    public function test_admin_xoa_danh_gia()
    {
        $review = Review::create([
            'user_id' => $this->normalUser->id,
            'place_id' => 1,
            'rating' => 4,
            'comment' => 'Tam on',
        ]);

        $response = $this->withHeaders($this->adminHeaders())
            ->deleteJson("/api/admin/reviews/{$review->id}");

        $response->assertStatus(200);
        $this->assertDatabaseMissing('reviews', ['id' => $review->id]);
    }
}
