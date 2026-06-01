<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        User::create([
            'name' => 'Admin TravelAI',
            'email' => 'admin@travelai.com',
            'password' => Hash::make('admin123'),
            'is_admin' => true,
            'is_active' => true,
        ]);

        User::create([
            'name' => 'Nguyễn Văn A',
            'email' => 'user@travelai.com',
            'password' => Hash::make('user123'),
            'is_admin' => false,
            'is_active' => true,
        ]);
    }
}
