# TravelAI - XAMPP, Laravel 11, and Google Maps Key Setup Guide

This document provides step-by-step setup guides to launch the backend REST API, database, and obtain necessary client API keys.

---

## Part 1: Setting up the MySQL Database via XAMPP

1. **Download & Install XAMPP**:
   - Download XAMPP from [Apache Friends](https://www.apachefriends.org/) (make sure it includes PHP 8.2+ to meet Laravel 11 requirements).
   - Install and open the **XAMPP Control Panel**.

2. **Start Services**:
   - In the XAMPP Control Panel, click statutory **Start** buttons next to **Apache** and **MySQL**.
   - Ensure both statuses turn green.

3. **Import database**:
   - Click the **Admin** button next to MySQL, or navigate to http://localhost/phpmyadmin/ in your web browser.
   - Click **New** in the left sidebar.
   - Enter `travelai` as the database name and select `utf8mb4_general_ci` collation, then click **Create**.
   - Select the newly created `travelai` database, go to the **Import** tab.
   - Click **Choose File**, select the `travelai.sql` file provided in the project root, and click **Import** (at the bottom).

---

## Part 2: Backend Laravel 11 Installation & Running

1. **Create the Project**:
   Open a terminal and run the composer command to create a new Laravel project:
   ```bash
   composer create-project laravel/laravel travelai-backend
   cd travelai-backend
   ```

2. **Install Required Packages**:
   Install Laravel Sanctum and the OpenAI API PHP client:
   ```bash
   composer require laravel/sanctum
   composer require openai-php/client
   ```

3. **Configure Environment File (`.env`)**:
   Open the `.env` file inside your Laravel root and configure the database connection and OpenAI credentials:
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=travelai
   DB_USERNAME=root
   DB_PASSWORD=

   # Add OpenAI Key
   OPENAI_API_KEY=your_openai_api_key_here
   ```

4. **Initialize Sanctum Configuration**:
   ```bash
   php artisan sanctum:install
   ```

5. **Start Laravel API Server**:
   ```bash
   php artisan serve --host=0.0.0.0 --port=8000
   ```
   The backend API is now running and reachable at:
   - Android Emulator Client Base URL: `http://10.0.2.2:8000/api`
   - iOS / Web / Localhost Base URL: `http://localhost:8000/api`

---

## Part 3: Steps to Obtain Google Maps API Key

To display interactive Google Maps on iOS and Android devices, you need an API Key configured in your mobile files:

1. **Google Cloud Console**:
   - Go to the [Google Cloud Console](https://console.cloud.google.com/).
   - Click the project dropdown and create a new project named `TravelAI`.

2. **Enable Maps SDK Libraries**:
   - In the left sidebar, navigate to **APIs & Services** > **Library**.
   - Search for **Maps SDK for Android** and click **Enable**.
   - Search for **Maps SDK for iOS** and click **Enable**.

3. **Generate API Key Credentials**:
   - Navigate to **APIs & Services** > **Credentials**.
   - Click **+ Create Credentials** at the top, then select **API Key**.
   - Copy the generated API Key.

4. **Add Restrictions (Highly Recommended)**:
   - Click **Edit API Key** to secure your key.
   - Under **API restrictions**, select **Restrict key**, check **Maps SDK for Android** and **Maps SDK for iOS**, and click **Save**.
