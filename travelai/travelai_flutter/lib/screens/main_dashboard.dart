import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/place.dart';
import '../providers/travel_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_chat_bubble.dart';
import '../widgets/place_card.dart';
import 'map_tab.dart';
import 'favorites_tab.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedTab = 0;
  bool _showAiChat = false;

  void _navigateToDetail(int placeId) {
    Navigator.pushNamed(context, '/place_detail', arguments: placeId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TravelProvider>();
    final isDesktop = MediaQuery.of(context).size.shortestSide >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.travel_explore, color: AppColors.accentOrange),
            const SizedBox(width: 8),
            Text('TravelAI',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText(context),
                    fontSize: 18.0)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _openSearch(context),
            icon: Icon(Icons.search, color: AppColors.primaryText(context)),
            tooltip: 'Tìm kiếm địa điểm',
          ),
          IconButton(
            onPressed: () {
              themeNotifier.value = themeNotifier.value == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
            icon: Icon(
              themeNotifier.value == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: AppColors.primaryText(context),
            ),
            tooltip: 'Chuyển chế độ sáng/tối',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            icon: Icon(Icons.person, color: AppColors.primaryText(context)),
            tooltip: 'Hồ sơ',
          ),
          if (provider.currentUser?.isAdmin == true)
            IconButton(
              onPressed: () async {
                await Navigator.pushNamed(context, '/admin');
                if (mounted) {
                  await context.read<TravelProvider>().loadInitialData();
                }
              },
              icon: const Icon(Icons.admin_panel_settings,
                  color: AppColors.accentOrange),
              tooltip: 'Admin Panel',
            ),
          IconButton(
            onPressed: () {
              provider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: Icon(Icons.exit_to_app, color: AppColors.primaryText(context)),
          ),
        ],
        backgroundColor: AppColors.appBar(context),
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              backgroundColor: AppColors.card(context),
              selectedIndex: _selectedTab,
              onDestinationSelected: (index) =>
                  setState(() => _selectedTab = index),
              leading: const SizedBox(height: 16),
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.map, color: AppColors.secondaryText(context)),
                  selectedIcon:
                      Icon(Icons.map, color: AppColors.accentOrange),
                  label: Text('Bản đồ',
                      style: TextStyle(color: AppColors.primaryText(context), fontSize: 12)),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite_border, color: AppColors.secondaryText(context)),
                  selectedIcon:
                      Icon(Icons.favorite, color: AppColors.accentOrange),
                  label: Text('Yêu thích',
                      style: TextStyle(color: AppColors.primaryText(context), fontSize: 12)),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                MapTab(onNavigateToDetail: _navigateToDetail),
                FavoritesTab(onNavigateToDetail: _navigateToDetail),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              backgroundColor: AppColors.card(context),
              selectedIndex: _selectedTab,
              onDestinationSelected: (index) =>
                  setState(() => _selectedTab = index),
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.map, color: AppColors.secondaryText(context)),
                  selectedIcon:
                      Icon(Icons.map, color: AppColors.accentOrange),
                  label: 'Bản đồ',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border, color: AppColors.secondaryText(context)),
                  selectedIcon:
                      Icon(Icons.favorite, color: AppColors.accentOrange),
                  label: 'Yêu thích',
                ),
              ],
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
            ),
      floatingActionButton: _showAiChat
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openAiChat(context),
              backgroundColor: AppColors.accentOrange,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(
                MediaQuery.of(context).size.shortestSide < 600 ? 'AI' : 'Trợ lý AI',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,
    );
  }

  void _openAiChat(BuildContext context) {
    setState(() => _showAiChat = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => AiChatBubble(
        onNavigateToDetail: _navigateToDetail,
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _showAiChat = false);
    });
  }

  void _openSearch(BuildContext context) {
    context.read<TravelProvider>().loadInitialData();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceSearchScreen(
          onNavigateToDetail: _navigateToDetail,
        ),
      ),
    );
  }
}

class PlaceSearchScreen extends StatefulWidget {
  final void Function(int placeId) onNavigateToDetail;

  const PlaceSearchScreen({super.key, required this.onNavigateToDetail});

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final _searchCtrl = TextEditingController();
  List<Place> _results = [];
  List<Place> _cachedPlaces = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onQueryChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final provider = context.read<TravelProvider>();
    _doSearch(_searchCtrl.text, provider.allPlaces);
  }

  void _doSearch(String query, List<Place> allPlaces) {
    final q = query.toLowerCase().trim();
    setState(() {
      _cachedPlaces = allPlaces;
      if (q.isEmpty) {
        _results = [];
      } else {
        _results = allPlaces.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.address.toLowerCase().contains(q)
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TravelProvider>();
    if (_cachedPlaces != provider.allPlaces && _searchCtrl.text.isNotEmpty) {
      _doSearch(_searchCtrl.text, provider.allPlaces);
    }

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(context),
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm tên quán, địa điểm...',
            hintStyle: TextStyle(color: AppColors.secondaryText(context)),
            border: InputBorder.none,
          ),
          style: TextStyle(color: AppColors.primaryText(context), fontSize: 16),
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _results = []);
              },
              icon: Icon(Icons.clear, color: AppColors.secondaryText(context)),
            ),
        ],
      ),
      body: _results.isEmpty && _searchCtrl.text.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 48, color: AppColors.secondaryText(context)),
                  SizedBox(height: 8),
                  Text('Không tìm thấy địa điểm phù hợp',
                      style: TextStyle(color: AppColors.secondaryText(context))),
                ],
              ),
            )
          : _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: AppColors.secondaryText(context)),
                      SizedBox(height: 12),
                      Text('Gõ tên địa điểm bạn muốn tìm',
                          style: TextStyle(color: AppColors.secondaryText(context))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final spot = _results[i];
                    return PlaceCard(
                      place: spot,
                      isFavorite: provider.favoritesList.contains(spot.id),
                      onFavoriteToggle: () =>
                          provider.toggleFavorite(spot.id),
                      onCardClick: () {
                        widget.onNavigateToDetail(spot.id);
                      },
                    );
                  },
                ),
    );
  }
}
