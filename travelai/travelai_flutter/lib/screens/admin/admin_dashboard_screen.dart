import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/travel_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/proxied_image.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getAdminDashboard();
    if (mounted) {
      setState(() {
        _stats = data;
        _loading = false;
        _error = data == null ? 'Không thể tải dữ liệu từ server' : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TravelProvider>();
    final user = provider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text('Admin Dashboard',
            style: TextStyle(
                color: AppColors.primaryText(context),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        backgroundColor: AppColors.appBar(context),
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accentOrange.withAlpha(40),
              backgroundImage: user?.avatar != null
                  ? proxiedNetworkImageProvider(user!.avatar!)
                  : null,
              child: user?.avatar == null
                  ? Text(
                      (user?.name.isNotEmpty == true
                              ? user!.name[0]
                              : 'A')
                          .toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.accentOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    )
                  : null,
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentOrange))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load,
                          child: const Text('Thử lại')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatGrid(),
                        const SizedBox(height: 24),
                        if (MediaQuery.of(context).size.shortestSide >= 900)
                          _buildChartsRow()
                        else ...[
                          _buildPieChartSection(),
                          const SizedBox(height: 24),
                          _buildBarChartSection(),
                        ],
                        const SizedBox(height: 24),
                        _buildRecentUsers(),
                        const SizedBox(height: 16),
                        _buildTopPlaces(),
                        const SizedBox(height: 32),
                        _buildRatingDistribution(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildChartsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPieChartSection()),
        const SizedBox(width: 24),
        Expanded(child: _buildBarChartSection()),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final provider = context.read<TravelProvider>();
    return Drawer(
      backgroundColor: AppColors.card(context),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppColors.background(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.admin_panel_settings,
                    color: AppColors.accentOrange, size: 48),
                const SizedBox(height: 8),
                Text('TravelAI Admin',
                    style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold)),
                Text(provider.currentUser?.email ?? '',
                    style: TextStyle(color: AppColors.secondaryText(context), fontSize: 12)),
              ],
            ),
          ),
          _drawerItem(
              Icons.dashboard, 'Dashboard', () => Navigator.pop(context)),
          _drawerItem(Icons.person, 'Hồ sơ', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/profile');
          }),
          _drawerItem(Icons.category, 'Danh mục', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/admin/categories');
          }),
          _drawerItem(Icons.place, 'Địa điểm', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/admin/places');
          }),
          _drawerItem(Icons.people, 'Người dùng', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/admin/users');
          }),
          _drawerItem(Icons.reviews, 'Đánh giá', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/admin/reviews');
          }),
          _drawerItem(Icons.history, 'AI Logs', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/admin/ai-logs');
          }),
          const Divider(color: Colors.grey),
          _drawerItem(Icons.arrow_back, 'Quay lại App', () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/main');
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(label, style: TextStyle(color: AppColors.primaryText(context))),
      onTap: onTap,
    );
  }

  Widget _buildStatGrid() {
    final sw = MediaQuery.of(context).size.shortestSide;
    final isPhone = sw < 600;
    final isTablet = sw >= 600 && sw < 900;

    final crossAxisCount = isTablet ? 3 : isPhone ? 2 : 5;
    final aspectRatio = isPhone ? 1.1 : isTablet ? 1.2 : 1.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 5,
      itemBuilder: (context, index) {
        final label = ['Người dùng', 'Địa điểm', 'Danh mục', 'Đánh giá', 'AI Logs'][index];
        final count = [ _stats?['total_users'] ?? 0, _stats?['total_places'] ?? 0, _stats?['total_categories'] ?? 0, _stats?['total_reviews'] ?? 0, _stats?['total_ai_logs'] ?? 0 ][index];
        final icon = [Icons.people, Icons.place, Icons.category, Icons.reviews, Icons.history][index];
        final color = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal][index];
        return Card(
          color: AppColors.card(context),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(height: 6),
                Text('$count',
                    style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
                Text(label,
                    style: TextStyle(
                        color: AppColors.secondaryText(context),
                        fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPieChartSection() {
    final placesByCategory =
        (_stats?['places_by_category'] as List? ?? []).cast<Map<String, dynamic>>();

    if (placesByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
    ];

    return Card(
      color: AppColors.card(context),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phân bố địa điểm theo danh mục',
                style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(
              height: MediaQuery.of(context).size.shortestSide < 600 ? 180 : 220,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: placesByCategory.asMap().entries.map((e) {
                          final count = _parseNum(e.value['places_count']).toInt();
                          return PieChartSectionData(
                            value: count.toDouble(),
                            title: '$count',
                            radius: 40,
                            titleStyle: TextStyle(
                                color: AppColors.primaryText(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                            color: colors[e.key % colors.length],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: placesByCategory.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colors[e.key % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              e.value['name'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartSection() {
    final places = (_stats?['top_places'] as List? ?? []).cast<Map<String, dynamic>>();

    if (places.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxRating = 5.0;

    return Card(
      color: AppColors.card(context),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Địa điểm đánh giá cao nhất',
                style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(
              height: MediaQuery.of(context).size.shortestSide < 600 ? 180 : 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxRating,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final name = places[groupIndex]['name'] ?? '';
                        return BarTooltipItem(
                          '$name\n${rod.toY.toStringAsFixed(1)}',
                          TextStyle(
                              color: AppColors.primaryText(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= places.length) {
                            return const SizedBox.shrink();
                          }
                          final name = places[index]['name'] as String? ?? '';
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              name.length > 8
                                  ? '${name.substring(0, 8)}..'
                                  : name,
                              style:
                                  TextStyle(color: AppColors.secondaryText(context), fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style:
                                TextStyle(color: AppColors.secondaryText(context), fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.primaryText(context).withAlpha(15),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: places.asMap().entries.map((e) {
                    final rating = _parseNum(e.value['rating_avg']);
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: rating,
                          color: AppColors.accentOrange,
                          width: MediaQuery.of(context).size.shortestSide < 600 ? 16 : 22,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingDistribution() {
    final dist = _stats?['rating_distribution'] as Map<String, dynamic>? ?? {};

    if (dist.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = dist.values
        .map((e) => _parseNum(e).toInt())
        .fold<int>(0, (a, b) => a + b);

    if (total == 0) {
      return const SizedBox.shrink();
    }

    final barColors = [
      const Color(0xFFE53935),
      const Color(0xFFFB8C00),
      const Color(0xFFFFC107),
      const Color(0xFF8BC34A),
      const Color(0xFF43A047),
    ];

    return Card(
      color: AppColors.card(context),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phân bố đánh giá sao',
                style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 20),
            ...List.generate(5, (index) {
              final star = 5 - index;
              final count = _parseNum(dist['$star']).toInt();
              final pct = total > 0 ? count / total : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text('$star ★',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: AppColors.primaryText(context).withAlpha(20),
                          valueColor: AlwaysStoppedAnimation(
                              barColors[5 - star]),
                          minHeight: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text('$count',
                          style: TextStyle(
                              color: AppColors.secondaryText(context),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUsers() {
    final users =
        (_stats?['recent_users'] as List? ?? []).cast<Map<String, dynamic>>();
    return Card(
      color: AppColors.card(context),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Người dùng gần đây',
                style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 12),
            if (users.isEmpty)
              Text('Chưa có dữ liệu',
                  style: TextStyle(color: AppColors.secondaryText(context)))
            else
              ...users.take(5).map((u) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.accentOrange.withAlpha(40),
                          child: Text(
                            ((u['name'] as String?)?.isNotEmpty == true
                                    ? u['name'][0]
                                    : '?')
                                .toUpperCase(),
                            style: const TextStyle(
                                color: AppColors.accentOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u['name'] ?? '',
                                  style: TextStyle(
                                      color: AppColors.primaryText(context), fontSize: 13)),
                              Text(u['email'] ?? '',
                                  style: TextStyle(
                                      color: AppColors.secondaryText(context), fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPlaces() {
    final places =
        (_stats?['top_places'] as List? ?? []).cast<Map<String, dynamic>>();
    return Card(
      color: AppColors.card(context),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Địa điểm đánh giá cao nhất',
                style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 12),
            if (places.isEmpty)
              Text('Chưa có dữ liệu',
                  style: TextStyle(color: AppColors.secondaryText(context)))
            else
              ...places.take(5).map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.place,
                              color: AppColors.accentOrange, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(p['name'] ?? '',
                              style: TextStyle(
                                  color: AppColors.primaryText(context), fontSize: 13)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Color(0xFFFFD700), size: 13),
                              const SizedBox(width: 3),
                              Text('${p['rating_avg']}',
                                  style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  double _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
