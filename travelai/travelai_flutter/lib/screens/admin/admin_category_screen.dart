import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminCategoryScreen extends StatefulWidget {
  const AdminCategoryScreen({super.key});

  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
  List<dynamic> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getAdminCategories();
    if (mounted) setState(() { _categories = data; _loading = false; });
  }

  Future<void> _showForm({Map<String, dynamic>? cat}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CategoryForm(
          category: cat,
          onSave: () => _load(),
        ),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        title: Text('Xác nhận', style: TextStyle(color: AppColors.primaryText(context))),
        content: const Text('Xóa danh mục này?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ApiService.deleteAdminCategory(id);
      _load();
    }
  }

  IconData _icon(String? name) {
    switch (name) {
      case 'restaurant': return Icons.restaurant;
      case 'landmark': return Icons.location_on;
      case 'gamepad': return Icons.videogame_asset;
      case 'hotel': return Icons.hotel;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'nature': return Icons.nature;
      case 'beach': return Icons.beach_access;
      case 'museum': return Icons.museum;
      case 'temple': return Icons.temple_hindu;
      case 'coffee': return Icons.coffee;
      case 'bar': return Icons.local_bar;
      case 'sports': return Icons.sports_soccer;
      case 'spa': return Icons.spa;
      case 'cinema': return Icons.movie;
      case 'bus': return Icons.directions_bus;
      case 'airport': return Icons.airport_shuttle;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text('Quản lý Danh mục',
            style: TextStyle(color: AppColors.primaryText(context), fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.appBar(context),
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accentOrange),
            onPressed: () => _showForm(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentOrange))
          : _categories.isEmpty
              ? Center(child: Text('Chưa có danh mục', style: TextStyle(color: AppColors.secondaryText(context))))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    itemBuilder: (context, i) {
                      final c = _categories[i];
                      return Card(
                        color: AppColors.card(context),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accentOrange.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_icon(c['icon']), color: AppColors.accentOrange, size: 24),
                          ),
                          title: Text(c['name'] ?? '',
                              style: TextStyle(color: AppColors.primaryText(context), fontWeight: FontWeight.bold)),
                          subtitle: Text('ID: ${c['id']} | Icon: ${c['icon']}',
                              style: TextStyle(color: AppColors.secondaryText(context), fontSize: 11)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                onPressed: () => _showForm(cat: c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _delete(c['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class CategoryForm extends StatefulWidget {
  final Map<String, dynamic>? category;
  final VoidCallback onSave;

  const CategoryForm({super.key, this.category, required this.onSave});

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  late TextEditingController _nameCtrl;
  late String _selectedIcon;
  bool _saving = false;

  static const _iconOptions = [
    ('restaurant', Icons.restaurant, 'Ăn uống'),
    ('landmark', Icons.location_on, 'Danh lam'),
    ('hotel', Icons.hotel, 'Khách sạn'),
    ('shopping_bag', Icons.shopping_bag, 'Mua sắm'),
    ('gamepad', Icons.videogame_asset, 'Giải trí'),
    ('nature', Icons.nature, 'Thiên nhiên'),
    ('beach', Icons.beach_access, 'Bãi biển'),
    ('museum', Icons.museum, 'Bảo tàng'),
    ('temple', Icons.temple_hindu, 'Chùa/Đền'),
    ('coffee', Icons.coffee, 'Cà phê'),
    ('bar', Icons.local_bar, 'Bar/Nhậu'),
    ('sports', Icons.sports_soccer, 'Thể thao'),
    ('spa', Icons.spa, 'Spa/Thư giãn'),
    ('cinema', Icons.movie, 'Rạp phim'),
    ('bus', Icons.directions_bus, 'Xe buýt'),
    ('airport', Icons.airport_shuttle, 'Sân bay'),
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameCtrl = TextEditingController(text: c?['name'] ?? '');
    _selectedIcon = c?['icon'] ?? 'landmark';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final data = {'name': _nameCtrl.text.trim(), 'icon': _selectedIcon};
    if (widget.category == null) {
      await ApiService.createAdminCategory(data);
    } else {
      await ApiService.updateAdminCategory(widget.category!['id'], data);
    }

    if (mounted) {
      setState(() => _saving = false);
      widget.onSave();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final crossCount = MediaQuery.of(context).size.shortestSide < 600 ? 3 : 4;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          widget.category == null ? 'Thêm danh mục' : 'Sửa danh mục',
          style: TextStyle(color: AppColors.primaryText(context), fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.appBar(context),
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(color: AppColors.accentOrange, strokeWidth: 2),
                  )
                : const Text('Lưu',
                    style: TextStyle(
                        color: AppColors.accentOrange, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tên danh mục', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.fieldBg(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.fieldBorder(context)),
              ),
              child: TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: 'VD: Ẩm thực, Thắng cảnh...',
                  hintStyle: TextStyle(color: AppColors.secondaryText(context)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                style: TextStyle(color: AppColors.primaryText(context), fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Chọn biểu tượng', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: _iconOptions.length,
              itemBuilder: (context, i) {
                final (key, icon, label) = _iconOptions[i];
                final isSelected = _selectedIcon == key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = key),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentOrange.withAlpha(30) : AppColors.card(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.accentOrange : AppColors.fieldBorder(context),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon,
                            color: isSelected ? AppColors.accentOrange : Colors.white60,
                            size: 28),
                        const SizedBox(height: 4),
                        Text(label,
                            style: TextStyle(
                              color: isSelected ? AppColors.accentOrange : AppColors.secondaryText(context),
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
