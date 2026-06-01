import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/travel_provider.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hoàn thiện các thông tin hợp lệ')),
      );
      return;
    }

    setState(() => _loading = true);

    final provider = context.read<TravelProvider>();
    await provider.register(name, email, password);

    if (mounted) {
      setState(() => _loading = false);
      if (provider.currentUser != null) {
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryText(context).withAlpha(20),
                      ),
                      child: const Icon(Icons.travel_explore,
                          color: AppColors.accentOrange, size: 48),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Đăng Ký',
                      style: TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tạo tài khoản để khám phá',
                      style: TextStyle(color: AppColors.secondaryText(context)),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      color: AppColors.card(context),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: EdgeInsets.all(isPhone ? 24 : 32),
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Họ và Tên',
                                labelStyle:
                                    TextStyle(color: AppColors.secondaryText(context)),
                                prefixIcon: Icon(Icons.person,
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
                                labelText: 'Mật khẩu (tối thiểu 6 ký tự)',
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
                                onPressed: _loading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentOrange,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                child: _loading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                        color: AppColors.primaryText(context),
                                            strokeWidth: 2),
                                      )
                                    : const Text(
                                        'Đăng Ký Trải Nghiệm',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushReplacementNamed(
                                      context, '/login'),
                              child: Text(
                                'Đã có tài khoản? Quay về đăng nhập',
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
