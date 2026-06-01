<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Category;
use App\Models\Place;
use App\Models\Favorite;

// Test chức năng yêu thích địa điểm (favorites)
class FavoriteTest extends TestCase
{
    private User $user;
    private string $token;

    protected function setUp(): void
    {
        parent::setUp();

        // Tao du lieu mau
        $this->user = User::create([
            'name' => 'Nguyen Van A',
            'email' => 'a@test.com',
            'password' => bcrypt('123456'),
        ]);
        $this->token = $this->user->createToken('auth_token')->plainTextToken;

        Category::create(['id' => 1, 'name' => 'Am thuc', 'icon' => 'restaurant']);
        Place::create([
            'id' => 1, 'category_id' => 1, 'name' => 'Pho Bo Ha Noi',
            'description' => 'Mon ngon', 'address' => 'Ha Noi',
            'latitude' => 21.0, 'longitude' => 105.0,
        ]);
        Place::create([
            'id' => 2, 'category_id' => 1, 'name' => 'Bun Bo Hue',
            'description' => 'Mon ngon mien Trung', 'address' => 'Hue',
            'latitude' => 16.0, 'longitude' => 107.0,
        ]);
    }

    private function authHeaders(): array
    {
        return ['Authorization' => "Bearer $this->token"];
    }

    public function test_them_yeu_thich_thanh_cong()
    {
        $response = $this->withHeaders($this->authHeaders())
            ->postJson('/api/favorites/1');

        $response->assertStatus(201)
            ->assertJson(['message' => 'Đã thêm vào danh sách yêu thích.']);
    }

    public function test_them_yeu_thich_khi_chua_dang_nhap()
    {
        $response = $this->postJson('/api/favorites/1');
        $response->assertStatus(401);
    }

    public function test_them_yeu_thich_bi_trung_khong_tao_ban_ghi_moi()
    {
        // Them lan 1
        $this->withHeaders($this->authHeaders())->postJson('/api/favorites/1');

        // Them lan 2 (cung user, cung place)
        $response = $this->withHeaders($this->authHeaders())
            ->postJson('/api/favorites/1');

        $response->assertStatus(201);
        $response->assertJsonFragment(['message' => 'Đã thêm vào danh sách yêu thích.']);
        $this->assertDatabaseHas('favorites', [
            'user_id' => $this->user->id,
            'place_id' => 1,
        ]);
    }

    public function test_lay_danh_sach_yeu_thich()
    {
        Favorite::create(['user_id' => $this->user->id, 'place_id' => 1]);
        Favorite::create(['user_id' => $this->user->id, 'place_id' => 2]);

        $response = $this->withHeaders($this->authHeaders())
            ->getJson('/api/favorites');

        $response->assertStatus(200);
        $response->assertJsonFragment(['name' => 'Pho Bo Ha Noi']);
        $response->assertJsonFragment(['name' => 'Bun Bo Hue']);
    }

    public function test_xoa_yeu_thich_thanh_cong()
    {
        Favorite::create(['user_id' => $this->user->id, 'place_id' => 1]);

        $response = $this->withHeaders($this->authHeaders())
            ->deleteJson('/api/favorites/1');

        $response->assertStatus(200)
            ->assertJson(['message' => 'Đã xóa khỏi danh sách yêu thích.']);
        $this->assertDatabaseMissing('favorites', [
            'user_id' => $this->user->id,
            'place_id' => 1,
        ]);
    }

    public function test_lay_danh_sach_yeu_thich_khi_chua_co_gi()
    {
        $response = $this->withHeaders($this->authHeaders())
            ->getJson('/api/favorites');

        $response->assertStatus(200);
        $response->assertJson([]);
    }
}
