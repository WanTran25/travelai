import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/travel_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_dashboard.dart';
import 'screens/place_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_category_screen.dart';
import 'screens/admin/admin_place_screen.dart';
import 'screens/admin/admin_user_screen.dart';
import 'screens/admin/admin_review_screen.dart';
import 'screens/admin/admin_ai_log_screen.dart';
import 'theme/app_theme.dart';

class TravelApp extends StatefulWidget {
  const TravelApp({super.key});

  @override
  State<TravelApp> createState() => _TravelAppState();
}

class _TravelAppState extends State<TravelApp> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<TravelProvider>().init();
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final travelProvider = context.watch<TravelProvider>();
    final isLoggedIn = travelProvider.currentUser != null;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'TravelAI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: !_ready
              ? Scaffold(
                  backgroundColor: AppColors.darkBackground,
                  body: const Center(
                    child: CircularProgressIndicator(color: AppColors.accentOrange),
                  ),
                )
              : isLoggedIn ? const MainDashboard() : const LoginScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/main': (context) => const MainDashboard(),
          },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/place_detail':
            final placeId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) => PlaceDetailScreen(placeId: placeId),
            );
          case '/profile':
            final userId = settings.arguments as int?;
            return MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: userId),
            );
          case '/admin':
            return MaterialPageRoute(
              builder: (context) => const AdminDashboardScreen(),
            );
          case '/admin/categories':
            return MaterialPageRoute(
              builder: (context) => const AdminCategoryScreen(),
            );
          case '/admin/places':
            return MaterialPageRoute(
              builder: (context) => const AdminPlaceScreen(),
            );
          case '/admin/users':
            return MaterialPageRoute(
              builder: (context) => const AdminUserScreen(),
            );
          case '/admin/reviews':
            return MaterialPageRoute(
              builder: (context) => const AdminReviewScreen(),
            );
          case '/admin/ai-logs':
            return MaterialPageRoute(
              builder: (context) => const AdminAiLogScreen(),
            );
        }
        return null;
      },
    );
    },
  );
  }
}
