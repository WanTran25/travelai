# TravelAI - Các file kiểm thử

## Flutter Tests (travelai_flutter/test/)
Chạy bằng: `flutter test`

| File | Mô tả |
|------|-------|
| `model_test.dart` | Test serialize/deserialize Place, Category, TravelUser, Review, Favorite |
| `search_test.dart` | Test chức năng tìm kiếm địa điểm (lọc theo tên, mô tả, địa chỉ) |
| `database_test.dart` | Test các thao tác database local (CRUD categories, places, favorites, reviews) |
| `widget_test.dart` | Test widget cơ bản và theme |

## Laravel Backend Tests (backend/tests/)
Chạy bằng: `cd backend && vendor/bin/phpunit`

Yêu cầu: PHPUnit được cài đặt (`composer install`)

| File | Mô tả |
|------|-------|
| `Feature/AuthTest.php` | Test đăng ký, đăng nhập, đăng xuất |
| `Feature/PlaceCategoryTest.php` | Test xem danh mục và địa điểm |
| `Feature/FavoriteTest.php` | Test thêm/xoá danh sách yêu thích |
| `Feature/ReviewTest.php` | Test gửi đánh giá và phản ứng |
| `Feature/ProfileTest.php` | Test hồ sơ người dùng |
| `Feature/AdminTest.php` | Test admin dashboard và CRUD |
