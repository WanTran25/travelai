import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/travel_user.dart';
import '../models/place.dart';
import '../providers/travel_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/proxied_image.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TravelUser? _profileUser;
  List<Place>? _favoritePlaces;
  bool _loading = true;
  bool _editing = false;

  late TextEditingController _nameController;
  late TextEditingController _bioController;

  bool get _isOwnProfile {
    final currentUser = context.read<TravelProvider>().currentUser;
    return widget.userId == null || widget.userId == currentUser?.id;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final provider = context.read<TravelProvider>();
    final currentUser = provider.currentUser;

    if (_isOwnProfile && currentUser != null) {
      _profileUser = currentUser;
      _favoritePlaces = await _loadFavoritePlaces();
      if (mounted) setState(() => _loading = false);
      return;
    }

    final userId = widget.userId;
    if (userId == null) return;

    final data = await ApiService.getUserProfile(userId);
    if (data != null && mounted) {
      final userJson = data['user'] as Map<String, dynamic>;
      final placesRaw = data['favorite_places'] as List? ?? [];
      setState(() {
        _profileUser = TravelUser.fromJson(userJson);
        _favoritePlaces = placesRaw
            .map((e) => Place(
                  id: (e['id'] as num).toInt(),
                  categoryId: (e['category_id'] as num?)?.toInt() ?? 0,
                  name: e['name'] as String? ?? '',
                  description: e['description'] as String? ?? '',
                  address: e['address'] as String? ?? '',
                  latitude: (e['latitude'] as num?)?.toDouble() ?? 0,
                  longitude: (e['longitude'] as num?)?.toDouble() ?? 0,
                  imageUrl: e['image_url'] as String? ?? '',
                  ratingAvg: (e['rating_avg'] as num?)?.toDouble() ?? 0,
                ))
            .toList();
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<List<Place>> _loadFavoritePlaces() async {
    final provider = context.read<TravelProvider>();
    if (provider.isOnline) {
      return await ApiService.getFavoritePlaces();
    }
    return [];
  }

  void _startEditing() {
    _nameController.text = _profileUser?.name ?? '';
    _bioController.text = _profileUser?.bio ?? '';
    setState(() => _editing = true);
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, maxWidth: 512);
    if (file != null) {
      _saveAvatar(file);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (file != null) {
      _saveAvatar(file);
    }
  }

  Future<void> _saveAvatar(XFile file) async {
    final result = await ApiService.uploadAvatarFile(file);
    if (result != null && mounted) {
      final updated = TravelUser.fromJson(result['user'] as Map<String, dynamic>);
      context.read<TravelProvider>().updateCurrentUser(updated);
      setState(() => _profileUser = updated);
    }
  }

  Future<void> _saveProfile() async {
    final result = await ApiService.updateProfile(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
    );
    if (result != null && mounted) {
      final updated = TravelUser.fromJson(result['user'] as Map<String, dynamic>);
      final provider = context.read<TravelProvider>();
      provider.updateCurrentUser(updated);
      setState(() {
        _profileUser = updated;
        _editing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật hồ sơ!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          _isOwnProfile ? 'Hồ sơ của tôi' : 'Hồ sơ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        backgroundColor: AppColors.navyDark,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isOwnProfile && !_editing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _startEditing,
            ),
          if (_isOwnProfile && _editing) ...[
            TextButton(
              onPressed: () => setState(() => _editing = false),
              child: const Text('Huỷ'),
            ),
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Lưu'),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentOrange))
          : _profileUser == null
              ? const Center(child: Text('Không tìm thấy người dùng', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 24),
                        if (_editing) _buildEditForm(),
                        if (!_editing && (_profileUser!.bio?.isNotEmpty == true))
                          _buildBioSection(),
                        const SizedBox(height: 24),
                        _buildFavoritePlacesSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    final user = _profileUser!;
    ImageProvider? avatarImage;
    if (user.avatar != null && user.avatar!.isNotEmpty) {
      if (user.avatar!.startsWith('http://') || user.avatar!.startsWith('https://')) {
        avatarImage = proxiedNetworkImageProvider(user.avatar!);
      } else {
        try {
          if (File(user.avatar!).existsSync()) {
            avatarImage = FileImage(File(user.avatar!));
          }
        } catch (_) {
          avatarImage = proxiedNetworkImageProvider(user.avatar!);
        }
      }
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _isOwnProfile && _editing ? _showAvatarPicker : null,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.navyDark,
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accentOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      )
                    : null,
              ),
              if (_editing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          user.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatChip(Icons.favorite, '${user.favoritesCount ?? _favoritePlaces?.length ?? 0} yêu thích'),
            const SizedBox(width: 16),
            _buildStatChip(Icons.reviews, '${user.reviewsCount ?? 0} đánh giá'),
          ],
        ),
      ],
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chọn ảnh đại diện',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.accentOrange),
                title: const Text('Chụp ảnh', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.accentOrange),
                title: const Text('Chọn từ thư viện', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              if (_profileUser?.avatar != null && _profileUser!.avatar!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text('Xoá ảnh đại diện', style: TextStyle(color: Colors.redAccent)),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await ApiService.updateProfile(avatar: '');
                    if (result != null && mounted) {
                      final updated = TravelUser.fromJson(result['user'] as Map<String, dynamic>);
                      context.read<TravelProvider>().updateCurrentUser(updated);
                      setState(() => _profileUser = updated);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accentOrange),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return Card(
      color: AppColors.navyDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Giới thiệu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              _profileUser!.bio ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Card(
      color: AppColors.navyDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chỉnh sửa hồ sơ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Tên'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: _inputDecoration('Giới thiệu'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accentOrange),
      ),
    );
  }

  Widget _buildFavoritePlacesSection() {
    final places = _favoritePlaces;
    if (places == null || places.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Địa điểm yêu thích',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...places.map((place) => Card(
              color: AppColors.navyDark,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: place.imageUrl.isNotEmpty
                      ? ProxiedCachedImage(
                          imageUrl: place.imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey[800],
                          child: const Icon(Icons.place, color: Colors.white54),
                        ),
                ),
                title: Text(place.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text(place.address, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                trailing: const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                onTap: () => Navigator.pushNamed(context, '/place_detail', arguments: place.id),
              ),
            )),
      ],
    );
  }
}
