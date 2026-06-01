<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Category;
use App\Models\Place;

// Test các chức năng xem danh mục và địa điểm
class PlaceCategoryTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // Tao du lieu mau cho test
        Category::create(['id' => 1, 'name' => 'Am thuc', 'icon' => 'restaurant']);
        Category::create(['id' => 2, 'name' => 'Tham quan', 'icon' => 'landmark']);

        Place::create([
            'id' => 1, 'category_id' => 1, 'name' => 'Pho Bo Ha Noi',
            'description' => 'Mon ngon Ha Noi', 'address' => 'Hoan Kiem',
            'latitude' => 21.0, 'longitude' => 105.0,
        ]);
        Place::create([
            'id' => 2, 'category_id' => 2, 'name' => 'Ho Hoan Kiem',
            'description' => 'Dep lam', 'address' => 'Ha Noi',
            'latitude' => 21.5, 'longitude' => 105.5,
        ]);
    }

    public function test_lay_danh_sach_danh_muc()
    {
        $response = $this->getJson('/api/categories');
        $response->assertStatus(200);
        $response->assertJsonFragment(['name' => 'Am thuc']);
        $response->assertJsonFragment(['name' => 'Tham quan']);
    }

    public function test_lay_danh_sach_dia_diem()
    {
        $response = $this->getJson('/api/places');
        $response->assertStatus(200);
        $response->assertJsonFragment(['name' => 'Pho Bo Ha Noi']);
        $response->assertJsonFragment(['name' => 'Ho Hoan Kiem']);
    }

    public function test_loc_dia_diem_theo_danh_muc()
    {
        $response = $this->getJson('/api/places?category_id=1');
        $response->assertStatus(200);
        $response->assertJsonFragment(['name' => 'Pho Bo Ha Noi']);
        $response->assertJsonMissing(['name' => 'Ho Hoan Kiem']);
    }

    public function test_xem_chi_tiet_dia_diem()
    {
        $response = $this->getJson('/api/places/1');
        $response->assertStatus(200);
        $response->assertJson(['id' => 1, 'name' => 'Pho Bo Ha Noi']);
    }

    public function test_xem_chi_tiet_dia_diem_khong_ton_tai()
    {
        $response = $this->getJson('/api/places/999');
        $response->assertStatus(404);
    }
}
