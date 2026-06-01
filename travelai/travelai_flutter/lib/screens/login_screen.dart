import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/travel_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'demo@travelai.com');
  final _passwordController = TextEditingController(text: '123456');
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Vui lòng nhập email hợp lệ và mật khẩu tối thiểu 6 ký tự'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final provider = context.read<TravelProvider>();
    String? error;
    try {
      final ok = await provider.login(email, password);
      if (!ok) error = 'Không thể đăng nhập. Vui lòng thử lại.';
    } catch (e) {
      error = '$e';
    }

    if (mounted) {
      setState(() => _loading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error!)),
        );
      } else if (provider.currentUser != null) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.shortestSide < 600;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isPhone ? 24 : 48),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryText(context).withAlpha(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentOrange.withAlpha(76),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const Icon(
                        Icons.travel_explore,
                        color: AppColors.accentOrange,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TravelAI',
                      style: TextStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                    Text(
                      'Trí tuệ nhân tạo gợi ý lịch trình du lịch',
                      style: TextStyle(color: AppColors.secondaryText(context)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Card(
                      color: AppColors.card(context),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: EdgeInsets.all(isPhone ? 24 : 32),
                        child: Column(
                          children: [
                            Text(
                              'ĐĂNG NHẬP',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                                color: AppColors.primaryText(context),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle:
                                    TextStyle(color: AppColors.secondaryText(context)),
                                prefixIcon: Icon(Icons.email,
                                    color: AppColors.secondaryText(context), size: 20),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: AppColors.accentOrange),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: AppColors.secondaryText(context)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              style: TextStyle(color: AppColors.primaryText(context)),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu',
                                labelStyle:
                                    TextStyle(color: AppColors.secondaryText(context)),
                                prefixIcon: Icon(Icons.lock,
                                    color: AppColors.secondaryText(context), size: 20),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: AppColors.accentOrange),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: AppColors.secondaryText(context)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              style: TextStyle(color: AppColors.primaryText(context)),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentOrange,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2),
                                      )
                                    : const Text(
                                        'Đăng Nhập',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushReplacementNamed(
                                      context, '/register'),
                              child: Text(
                                'Chưa có tài khoản? Đăng ký ngay',
                                style: TextStyle(color: AppColors.secondaryText(context)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
