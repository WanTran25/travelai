<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Category;
use App\Models\Place;

// Test chức năng hồ sơ người dùng (profile)
class ProfileTest extends TestCase
{
    private User $user;
    private string $token;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::create([
            'name' => 'Nguyen Van A',
            'email' => 'a@test.com',
            'password' => bcrypt('123456'),
        ]);
        $this->token = $this->user->createToken('auth_token')->plainTextToken;

        Category::create(['id' => 1, 'name' => 'Am thuc', 'icon' => 'restaurant']);
        Place::create([
            'id' => 1, 'category_id' => 1, 'name' => 'Pho Bo',
            'description' => 'Mon ngon', 'address' => 'Ha Noi',
            'latitude' => 21.0, 'longitude' => 105.0,
        ]);
    }

    private function authHeaders(): array
    {
        return ['Authorization' => "Bearer $this->token"];
    }

    public function test_xem_ho_so_cua_user_khac()
    {
        $response = $this->withHeaders($this->authHeaders())
            ->getJson("/api/profile/{$this->user->id}");
        $response->assertStatus(200)
            ->assertJsonStructure(['user', 'favorite_places']);
    }

    public function test_xem_ho_so_user_khong_ton_tai()
    {
        $response = $this->getJson('/api/profile/999');
        $response->assertStatus(404);
    }

    public function test_cap_nhat_ten_ho_so()
    {
        $response = $this->withHeaders($this->authHeaders())
            ->putJson('/api/profile', ['name' => 'Nguyen Van B']);

        $response->assertStatus(200)
            ->assertJson(['user' => ['name' => 'Nguyen Van B']]);
    }

    public function test_cap_nhat_bio_ho_so()
    {
        $response = $this->withHeaders($this->authHeaders())
            ->putJson('/api/profile', ['bio' => 'Toi yeu du lich']);

        $response->assertStatus(200);
        $this->assertDatabaseHas('users', [
            'id' => $this->user->id,
            'bio' => 'Toi yeu du lich',
        ]);
    }

    public function test_cap_nhat_ho_so_khi_chua_dang_nhap()
    {
        $response = $this->putJson('/api/profile', ['name' => 'New Name']);
        $response->assertStatus(401);
    }
}
