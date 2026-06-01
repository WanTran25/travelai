<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        Category::insert([
            ['id' => 1, 'name' => 'Ẩm thực', 'icon' => 'restaurant'],
            ['id' => 2, 'name' => 'Tham quan', 'icon' => 'landmark'],
            ['id' => 3, 'name' => 'Giải trí', 'icon' => 'gamepad'],
            ['id' => 4, 'name' => 'Lưu trú', 'icon' => 'hotel'],
            ['id' => 5, 'name' => 'Mua sắm', 'icon' => 'shopping_bag'],
        ]);
    }
}
