<?php

namespace Database\Seeders;

use App\Models\Place;
use Illuminate\Database\Seeder;

class PlaceSeeder extends Seeder
{
    public function run(): void
    {
        Place::insert([
            [
                'id' => 1,
                'category_id' => 2,
                'name' => 'Hồ Hoàn Kiếm',
                'description' => 'Trái tim xanh của thủ đô Hà Nội, phong cảnh thơ mộng gắn liền với tháp Rùa cổ kính và cầu Thê Húc đỏ rực, thích hợp đi dạo, ngắm cảnh tinh khôi mỗi sớm mai.',
                'address' => 'Phố Đinh Tiên Hoàng, Hàng Trống, Hoàn Kiếm, Hà Nội',
                'latitude' => 21.028511,
                'longitude' => 105.852441,
                'image_url' => 'https://images.unsplash.com/photo-1509060464153-4466739ef02e',
                'rating_avg' => 4.8,
            ],
            [
                'id' => 2,
                'category_id' => 1,
                'name' => 'Chợ Bến Thành',
                'description' => 'Biểu tượng giao thương sầm uất lâu đời của Sài Gòn. Nơi hội tụ các gian hàng đồ thủ công mỹ nghệ tinh xảo cùng khu ẩm thực khổng lồ đa dạng các món ăn Nam Bộ.',
                'address' => 'Đường Lê Lợi, Bến Thành, Quận 1, TP. Hồ Chí Minh',
                'latitude' => 10.772535,
                'longitude' => 106.698031,
                'image_url' => 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1',
                'rating_avg' => 4.5,
            ],
            [
                'id' => 3,
                'category_id' => 2,
                'name' => 'Nhà Thờ Đức Bà',
                'description' => 'Công trình kiến trúc vĩ đại mang đậm dấu ấn phong cách Romanesque phối hợp Gothic Pháp cổ tuyệt mĩ, một biểu tượng văn hóa tôn giáo và điểm check-in di sản.',
                'address' => '01 Công xã Paris, Bến Ngé, Quận 1, TP. Hồ Chí Minh',
                'latitude' => 10.779836,
                'longitude' => 106.699042,
                'image_url' => 'https://images.unsplash.com/photo-1568292342316-60aa3d36f4b3',
                'rating_avg' => 4.6,
            ],
            [
                'id' => 4,
                'category_id' => 2,
                'name' => 'Phố Cổ Hội An',
                'description' => 'Di sản văn hóa thế giới bình yên lưu giữ dấu ấn thời gian với từng mái ngói rêu phong, gạch ngói vàng cổ cùng lễ hội thả đèn hoa đăng lấp lánh ban đêm trên sông Hoài thơ mộng.',
                'address' => 'Minh An, Hội An, Quảng Nam',
                'latitude' => 15.877085,
                'longitude' => 108.327421,
                'image_url' => 'https://images.unsplash.com/photo-1596402184320-417d7178b2cd',
                'rating_avg' => 4.9,
            ],
            [
                'id' => 5,
                'category_id' => 5,
                'name' => 'Phố Đi Bộ Nguyễn Huệ',
                'description' => 'Đại lộ đi bộ hoành tráng sầm uất nhất cả nước. Địa chỉ lý tưởng để đi bộ dạo mát vui tươi, chụp ảnh lưu niệm náo nhiệt và thưởng thức ẩm thực trà sữa độc đáo.',
                'address' => 'Đường Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',
                'latitude' => 10.774577,
                'longitude' => 106.703215,
                'image_url' => 'https://images.unsplash.com/photo-1518173946687-a4c8a383392c',
                'rating_avg' => 4.7,
            ],
        ]);
    }
}
