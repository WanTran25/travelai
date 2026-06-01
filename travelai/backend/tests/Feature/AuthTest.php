<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;

// Test các chức năng đăng ký, đăng nhập, đăng xuất
class AuthTest extends TestCase
{
    public function test_dang_ky_thanh_cong()
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Nguyen Van A',
            'email' => 'a@test.com',
            'password' => '123456',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure(['user', 'access_token', 'token_type']);
    }

    public function test_dang_ky_email_da_ton_tai()
    {
        User::create([
            'name' => 'Existing',
            'email' => 'a@test.com',
            'password' => bcrypt('123456'),
        ]);

        $response = $this->postJson('/api/register', [
            'name' => 'Nguyen Van B',
            'email' => 'a@test.com',
            'password' => '123456',
        ]);

        $response->assertStatus(422);
    }

    public function test_dang_nhap_thanh_cong()
    {
        User::create([
            'name' => 'Nguyen Van A',
            'email' => 'a@test.com',
            'password' => bcrypt('123456'),
        ]);

        $response = $this->postJson('/api/login', [
            'email' => 'a@test.com',
            'password' => '123456',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure(['user', 'access_token', 'token_type']);
    }

    public function test_dang_nhap_sai_mat_khau()
    {
        User::create([
            'name' => 'Nguyen Van A',
            'email' => 'a@test.com',
            'password' => bcrypt('123456'),
        ]);

        $response = $this->postJson('/api/login', [
            'email' => 'a@test.com',
            'password' => 'sai_mat_khau',
        ]);

        $response->assertStatus(422);
    }

    public function test_dang_nhap_khi_tai_khoan_bi_khoa()
    {
        User::create([
            'name' => 'Nguyen Van A',
            'email' => 'a@test.com',
            'password' => bcrypt('123456'),
            'is_active' => false,
        ]);

        $response = $this->postJson('/api/login', [
            'email' => 'a@test.com',
            'password' => '123456',
        ]);

        $response->assertStatus(422);
    }

    public function test_lay_thong_tin_user_da_dang_nhap()
    {
        $user = User::create([
            'name' => 'Nguyen Van A',
            'email' => 'a@test.com',
            'password' => bcrypt('123456'),
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/user');

        $response->assertStatus(200)
            ->assertJson(['id' => $user->id, 'email' => 'a@test.com']);
    }

    public function test_lay_thong_tin_user_khi_chua_dang_nhap()
    {
        $response = $this->getJson('/api/user');
        $response->assertStatus(401);
    }

    public function test_dang_xuat_thanh_cong()
    {
        $user = User::create([
            'name' => 'Nguyen Van A',
            'email' => 'a@test.com',
            'password' => bcrypt('123456'),
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->postJson('/api/logout');

        $response->assertStatus(200)
            ->assertJson(['message' => 'Đăng xuất thành công.']);
    }
}
