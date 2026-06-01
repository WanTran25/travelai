import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminPlaceScreen extends StatefulWidget {
  const AdminPlaceScreen({super.key});

  @override
  State<AdminPlaceScreen> createState() => _AdminPlaceScreenState();
}

class _AdminPlaceScreenState extends State<AdminPlaceScreen> {
  List<dynamic> _places = [];
  bool _loading = true;
  List<dynamic> _categories = [];
  final _searchCtl = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  List<dynamic> get _filteredPlaces {
    if (_searchQuery.isEmpty) return _places;
    final q = _searchQuery.toLowerCase();
    return _places.where((p) {
      final name = (p['name'] as String? ?? '').toLowerCase();
      final address = (p['address'] as String? ?? '').toLowerCase();
      return name.contains(q) || address.contains(q);
    }).toList();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = value);
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getAdminPlaces(),
      ApiService.getAdminCategories(),
    ]);
    if (mounted) {
      setState(() {
        _places = results[0] as List;
        _categories = results[1] as List;
        _loading = false;
      });
    }
  }

  Future<void> _showForm({Map<String, dynamic>? place}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PlaceForm(
          place: place,
          categories: _categories,
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
        backgroundColor: AppColors.navyDark,
        title: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
        content: const Text('Xóa địa điểm này?',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ApiService.deleteAdminPlace(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Quản lý Địa điểm',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.navyDark,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accentOrange),
            onPressed: () => _showForm(),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.accentOrange))
          : RefreshIndicator(
                          onRefresh: _load,
                          child: CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 16, 16, 8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.navyDark,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border:
                                          Border.all(color: Colors.white24),
                                    ),
                                    child: TextField(
                                      controller: _searchCtl,
                                      onChanged: _onSearchChanged,
                                      decoration: const InputDecoration(
                                        hintText: 'Tìm theo tên hoặc địa chỉ...',
                                        hintStyle:
                                            TextStyle(color: Colors.grey),
                                        prefixIcon: Icon(Icons.search,
                                            color: Colors.grey),
                                        border: InputBorder.none,
                                        contentPadding:
                                            EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 14),
                                      ),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14),
                                    ),
                                  ),
                                ),
                              ),
                              if (_filteredPlaces.isEmpty)
                                const SliverFillRemaining(
                                  child: Center(
                                    child: Text('Không tìm thấy địa điểm',
                                        style:
                                            TextStyle(color: Colors.grey)),
                                  ),
                                )
                              else
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, i) {
                                      final p = _filteredPlaces[i];
                                      final catName = _categories
                                          .where((c) =>
                                              c['id'] == p['category_id'])
                                          .map((c) => c['name'] as String)
                                          .firstOrNull;
                                      return Card(
                                        color: AppColors.navyDark,
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentOrange
                                                  .withAlpha(25),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.place,
                                                color:
                                                    AppColors.accentOrange),
                                          ),
                                          title: Text(p['name'] ?? '',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                          subtitle: Text(
                                            '${catName ?? "Cat ${p['category_id']}"}  ⭐ ${p['rating_avg'] ?? 0}',
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit,
                                                    color: Colors.blue,
                                                    size: 20),
                                                onPressed: () =>
                                                    _showForm(place: p),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red,
                                                    size: 20),
                                                onPressed: () =>
                                                    _delete(p['id']),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    childCount: _filteredPlaces.length,
                                  ),
                                ),
                            ],
                          ),
                        ),
    );
  }
}

class PlaceForm extends StatefulWidget {
  final Map<String, dynamic>? place;
  final List<dynamic> categories;
  final VoidCallback onSave;

  const PlaceForm({
    super.key,
    this.place,
    required this.categories,
    required this.onSave,
  });

  @override
  State<PlaceForm> createState() => _PlaceFormState();
}

class _PlaceFormState extends State<PlaceForm> {
  late int _categoryId;
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _addrCtrl;
  late TextEditingController _imgCtrl;
  late LatLng _position;
  bool _saving = false;
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  final _searchFocus = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    final p = widget.place;
    _categoryId = p != null ? (p['category_id'] as num?)?.toInt() ?? 1 : 1;
    _nameCtrl = TextEditingController(text: p?['name'] ?? '');
    _descCtrl = TextEditingController(text: p?['description'] ?? '');
    _addrCtrl = TextEditingController(text: p?['address'] ?? '');
    _imgCtrl = TextEditingController(text: p?['image_url'] ?? '');
    final lat = _parseCoord(p?['latitude']) ?? 21.0285;
    final lng = _parseCoord(p?['longitude']) ?? 105.8542;
    _position = LatLng(lat, lng);
    _searchCtrl.addListener(_onSearchChanged);
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addrCtrl.dispose();
    _imgCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final q = _searchCtrl.text.trim();
    if (q.length < 3) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetchSuggestions(q));
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) return;
    setState(() => _searching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1&countrycodes=vn',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'TravelAI/1.0',
      });
      if (res.statusCode == 200) {
        final data = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
        if (mounted) setState(() { _suggestions = data; _showSuggestions = data.isNotEmpty; });
      }
    } catch (_) {}
    if (mounted) setState(() => _searching = false);
  }

  Widget _buildSuggestionsDropdown() {
    if (!_showSuggestions || _suggestions.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      constraints: const BoxConstraints(maxHeight: 260),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _suggestions.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.white12),
        itemBuilder: (context, i) {
          final s = _suggestions[i];
          final display = s['display_name'] as String? ?? '';
          final type = s['type'] as String? ?? '';
          final icon = _typeIcon(type);
          return ListTile(
            dense: true,
            leading: Icon(icon, color: AppColors.accentOrange, size: 20),
            title: Text(
              display,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              final lat = double.parse(s['lat'] as String);
              final lng = double.parse(s['lon'] as String);
              final addr = s['display_name'] as String? ?? '';
              setState(() {
                _position = LatLng(lat, lng);
                _addrCtrl.text = addr;
                _searchCtrl.text = addr;
                _showSuggestions = false;
                _suggestions = [];
              });
            },
          );
        },
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'road': case 'street': return Icons.directions;
      case 'suburb': case 'neighbourhood': return Icons.location_city;
      case 'city': case 'town': case 'village': return Icons.location_city;
      case 'amenity': case 'tourism': return Icons.place;
      default: return Icons.pin_drop;
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _searching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'TravelAI/1.0',
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat'] as String);
          final lng = double.parse(data[0]['lon'] as String);
          setState(() => _position = LatLng(lat, lng));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;

    setState(() => _saving = true);

    final data = {
      'category_id': _categoryId,
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'address': _addrCtrl.text.trim(),
      'latitude': _position.latitude,
      'longitude': _position.longitude,
      'image_url': _imgCtrl.text.trim(),
    };

    if (widget.place == null) {
      await ApiService.createAdminPlace(data);
    } else {
      await ApiService.updateAdminPlace(widget.place!['id'], data);
    }

    if (mounted) {
      setState(() => _saving = false);
      widget.onSave();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.shortestSide < 600;
    final mapHeight = isPhone ? 220.0 : 300.0;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          widget.place == null ? 'Thêm địa điểm' : 'Sửa địa điểm',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.navyDark,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: AppColors.accentOrange, strokeWidth: 2),
                  )
                : const Text('Lưu',
                    style: TextStyle(
                        color: AppColors.accentOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category dropdown
            _buildLabel('Danh mục'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.navyDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _categoryId,
                  isExpanded: true,
                  dropdownColor: AppColors.navyDark,
                  items: widget.categories.map((c) {
                    return DropdownMenuItem<int>(
                      value: c['id'] as int,
                      child: Row(
                        children: [
                          Icon(_catIcon(c['name'] ?? ''),
                              color: AppColors.accentOrange, size: 18),
                          const SizedBox(width: 8),
                          Text(c['name'] ?? '',
                              style:
                                  const TextStyle(color: Colors.white)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _categoryId = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name field
            _buildLabel('Tên địa điểm'),
            const SizedBox(height: 6),
            _buildField(_nameCtrl, 'Nhập tên địa điểm'),
            const SizedBox(height: 16),

            // Description
            _buildLabel('Mô tả'),
            const SizedBox(height: 6),
            _buildField(_descCtrl, 'Mô tả về địa điểm', maxLines: 4),
            const SizedBox(height: 16),

            // Address
            _buildLabel('Địa chỉ'),
            const SizedBox(height: 6),
            _buildField(_addrCtrl, 'Nhập địa chỉ'),
            const SizedBox(height: 16),

            // Image URL
            _buildLabel('URL hình ảnh'),
            const SizedBox(height: 6),
            _buildField(_imgCtrl, 'https://...'),
            const SizedBox(height: 20),

            // Map picker section
            _buildLabel('Tìm kiếm địa chỉ'),
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.navyDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          decoration: const InputDecoration(
                            hintText: 'VD: 123 Phạm Ngọc Thạch, Quy Nhơn...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                          ),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onSubmitted: _searchAddress,
                        ),
                      ),
                      if (_searching)
                        const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: AppColors.accentOrange, strokeWidth: 2),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: () => _searchAddress(_searchCtrl.text),
                          icon: const Icon(Icons.search,
                              color: AppColors.accentOrange),
                        ),
                    ],
                  ),
                ),
                _buildSuggestionsDropdown(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLabel('Vị trí trên bản đồ'),
                const Spacer(),
                Text(
                  '${_position.latitude.toStringAsFixed(4)}, ${_position.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Kéo/thả marker hoặc gõ địa chỉ để tìm',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: mapHeight,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _position,
                    initialZoom: 13,
                    onTap: (tapPos, latlng) {
                      setState(() => _position = latlng);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.travelai.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _position,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on,
                              color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 14));
  }

  Widget _buildField(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        minLines: maxLines > 1 ? 3 : 1,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  IconData _catIcon(String name) {
    switch (name.toLowerCase()) {
      case 'restaurant':
      case 'ăn uống':
        return Icons.restaurant;
      case 'landmark':
      case 'danh lam':
        return Icons.location_on;
      case 'gamepad':
      case 'giải trí':
        return Icons.videogame_asset;
      case 'hotel':
      case 'khách sạn':
        return Icons.hotel;
      case 'shopping':
      case 'mua sắm':
        return Icons.shopping_bag;
      default:
        return Icons.explore;
    }
  }

  double? _parseCoord(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
