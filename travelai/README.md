# TravelAI - AI Travel Assistant & Local Spots Finder

TravelAI là ứng dụng trợ lý du lịch thông minh giúp tìm kiếm địa điểm địa phương và gợi ý tùy chỉnh dựa trên AI.

## Công nghệ sử dụng

- **Frontend:** Flutter (Dart)
- **Backend:** Laravel 11 (PHP 8.2+)
- **Database:** MySQL
- **AI:** OpenAI API

## Cấu trúc dự án

```
travelai/
├── backend/           # Laravel REST API
├── travelai_flutter/   # Ứng dụng Flutter mobile
├── travelai.sql        # Database dump
└── XAMPP_LARAVEL_SETUP.md  # Hướng dẫn cài đặt chi tiết
```

## Hướng dẫn cài đặt

### Yêu cầu

- [Flutter SDK](https://flutter.dev) (Dart ^3.12)
- [PHP 8.2+](https://www.php.net/) & [Composer](https://getcomposer.org/)
- [XAMPP](https://www.apachefriends.org/) (hoặc MySQL server)
- [OpenAI API Key](https://platform.openai.com/api-keys)

### 1. Cài đặt Database

Xem hướng dẫn chi tiết tại [XAMPP_LARAVEL_SETUP.md](./XAMPP_LARAVEL_SETUP.md) — Phần 1.

### 2. Cài đặt Backend (Laravel)

```bash
cd backend
composer install
cp .env.example .env  # cấu hình database & OPENAI_API_KEY
php artisan key:generate
php artisan serve --host=0.0.0.0 --port=8000
```

API sẽ chạy tại `http://localhost:8000/api`.

### 3. Cài đặt Frontend (Flutter)

```bash
cd travelai_flutter
flutter pub get
flutter run
```

## API Endpoints

Backend cung cấp REST API với các endpoint chính:

- `POST /api/register` — Đăng ký
- `POST /api/login` — Đăng nhập
- `GET /api/places` — Danh sách địa điểm
- `POST /api/ai/suggest` — Gợi ý từ AI

## Tính năng chính

- Tìm kiếm địa điểm du lịch gần bạn
- Gợi ý thông minh dựa trên AI
- Bản đồ tương tác (Google Maps)
- Đăng nhập / đăng ký người dùng
- Cache dữ liệu offline
