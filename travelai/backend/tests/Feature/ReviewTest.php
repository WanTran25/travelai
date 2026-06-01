<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Category;
use App\Models\Place;
use App\Models\Review;

// Test chức năng đánh giá (review) và tương tác (reaction)
class ReviewTest extends TestCase
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
            'id' => 1, 'category_id' => 1, 'name' => 'Pho Bo Ha Noi',
            'description' => 'Mon ngon', 'address' => 'Ha Noi',
            'latitude' => 21.0, 'longitude' => 105.0,
        ]);
    }

    private function authHeaders(): array
    {
        return ['Authorization' => "Bearer $this->token"];
    }

    public function test_gui_danh_gia_thanh_cong()
    {
        $response = $this->withHeaders($this->authHeaders())
            ->postJson('/api/reviews', [
                'place_id' => 1,
                'rating' => 5,
                'comment' => 'Dia diem rat dep!',
            ]);

        $response->assertStatus(201)
            ->assertJsonStructure(['message', 'review']);
    }

    public function test_gui_danh_gia_khi_chua_dang_nhap()
    {
        $response = $this->postJson('/api/reviews', [
            'place_id' => 1,
            'rating' => 5,
            'comment' => 'OK',
        ]);

        $response->assertStatus(401);
    }

    public function test_gui_danh_gia_voi_rating_khong_hop_le()
    {
        $response = $this->withHeaders($this->authHeaders())
            ->postJson('/api/reviews', [
                'place_id' => 1,
                'rating' => 6,
                'comment' => 'OK',
            ]);

        $response->assertStatus(422);
    }

    public function test_xem_danh_gia_cua_mot_dia_diem()
    {
        Review::create([
            'user_id' => $this->user->id,
            'place_id' => 1,
            'rating' => 5,
            'comment' => 'Tuyet voi!',
        ]);

        $response = $this->withHeaders($this->authHeaders())
            ->getJson('/api/reviews/place/1');

        $response->assertStatus(200);
        $response->assertJsonFragment(['comment' => 'Tuyet voi!']);
    }

    public function test_danh_gia_cap_nhat_rating_trung_binh()
    {
        $this->withHeaders($this->authHeaders())->postJson('/api/reviews', [
            'place_id' => 1, 'rating' => 5, 'comment' => 'Tuyet!',
        ]);

        $this->assertDatabaseHas('places', ['id' => 1, 'rating_avg' => 5.0]);
    }

    public function test_phan_ung_voi_danh_gia()
    {
        $review = Review::create([
            'user_id' => $this->user->id,
            'place_id' => 1,
            'rating' => 4,
            'comment' => 'OK',
        ]);

        $response = $this->withHeaders($this->authHeaders())
            ->postJson("/api/reviews/{$review->id}/react", [
                'reaction' => 'like',
            ]);

        $response->assertStatus(201)
            ->assertJson(['reaction' => 'like']);
    }

    public function test_bo_phan_ung_khi_nut_cung_loai()
    {
        $review = Review::create([
            'user_id' => $this->user->id,
            'place_id' => 1,
            'rating' => 4,
            'comment' => 'OK',
        ]);

        // Like
        $this->withHeaders($this->authHeaders())
            ->postJson("/api/reviews/{$review->id}/react", ['reaction' => 'like']);

        // Unlike (nhan cung nut)
        $response = $this->withHeaders($this->authHeaders())
            ->postJson("/api/reviews/{$review->id}/react", ['reaction' => 'like']);

        $response->assertStatus(200)
            ->assertJson(['reaction' => null]);
    }

    public function test_phan_ung_voi_loai_reaction_khong_hop_le()
    {
        $review = Review::create([
            'user_id' => $this->user->id,
            'place_id' => 1,
            'rating' => 4,
            'comment' => 'OK',
        ]);

        $response = $this->withHeaders($this->authHeaders())
            ->postJson("/api/reviews/{$review->id}/react", [
                'reaction' => 'invalid',
            ]);

        $response->assertStatus(422);
    }
}
