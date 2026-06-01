import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  String? _error;
  final _searchCtl = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  List<dynamic> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    final q = _searchQuery.toLowerCase();
    return _users.where((u) {
      final name = (u['name'] as String? ?? '').toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();
      return name.contains(q) || email.contains(q);
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
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getAdminUsers();
      if (mounted) setState(() { _users = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Không thể tải dữ liệu'; _loading = false; });
    }
  }

  Future<void> _toggleActive(int id) async {
    try {
      await ApiService.toggleAdminUserActive(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _toggleAdmin(int id) async {
    try {
      await ApiService.toggleAdminUserAdmin(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        title: Text('Xác nhận', style: TextStyle(color: AppColors.primaryText(context))),
        content: const Text('Xóa người dùng này?', style: TextStyle(color: Colors.grey)),
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
      await ApiService.deleteAdminUser(id);
      _load();
    }
  }

  Future<void> _showCreateDialog() {
    final nameCtl = TextEditingController();
    final emailCtl = TextEditingController();
    final passCtl = TextEditingController();
    bool isAdmin = false;
    bool creating = false;

    return showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card(context),
          title: Text('Thêm người dùng',
              style: TextStyle(color: AppColors.primaryText(context))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtl,
                  style: TextStyle(color: AppColors.primaryText(context)),
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.accentOrange)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtl,
                  style: TextStyle(color: AppColors.primaryText(context)),
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.accentOrange)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtl,
                  style: TextStyle(color: AppColors.primaryText(context)),
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.accentOrange)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Admin',
                        style: TextStyle(color: AppColors.primaryText(context))),
                    const Spacer(),
                    Switch(
                      value: isAdmin,
                      activeColor: AppColors.accentOrange,
                      onChanged: (v) =>
                          setDialogState(() => isAdmin = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: creating ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: creating
                  ? null
                  : () async {
                      final name = nameCtl.text.trim();
                      final email = emailCtl.text.trim();
                      final pass = passCtl.text;
                      if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                        );
                        return;
                      }
                      setDialogState(() => creating = true);
                      try {
                        await ApiService.createAdminUser(
                          name: name,
                          email: email,
                          password: pass,
                          isAdmin: isAdmin,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _load();
                      } catch (e) {
                        if (ctx.mounted) {
                          setDialogState(() => creating = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange),
              child: creating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Tạo',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text('Quản lý Người dùng',
            style: TextStyle(color: AppColors.primaryText(context), fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.appBar(context),
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add, color: AppColors.primaryText(context)),
            tooltip: 'Thêm người dùng',
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentOrange))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: AppColors.secondaryText(context))),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentOrange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                    onRefresh: _load,
                    child: _filteredUsers.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 200),
                              if (_searchQuery.isNotEmpty)
                                Center(child: Text('Không tìm thấy người dùng', style: TextStyle(color: AppColors.secondaryText(context))))
                              else
                                Center(child: Text('Chưa có người dùng', style: TextStyle(color: AppColors.secondaryText(context)))),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
                            itemCount: _filteredUsers.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            controller: _searchCtl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm theo tên hoặc email...',
                              hintStyle: const TextStyle(color: Colors.grey),
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.grey),
                                      onPressed: () {
                                        _searchCtl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppColors.navyDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: _onSearchChanged,
                          ),
                        );
                      }
                      final u = _filteredUsers[i - 1];
                      final isAdmin = u['is_admin'] == true || u['is_admin'] == 1;
                      final isActive = (u['is_active'] as bool?) ?? true;
                      return Card(
                        color: AppColors.navyDark,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isAdmin ? AppColors.accentOrange : Colors.grey,
                                radius: 20,
                                child: Icon(Icons.person, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u['name'] ?? '',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text(u['email'] ?? '',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    Row(
                                      children: [
                                        if (isAdmin)
                                          const Chip(
                                            label: Text('Admin', style: TextStyle(color: Colors.white, fontSize: 10)),
                                            backgroundColor: AppColors.accentOrange,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        Chip(
                                          label: Text(
                                            isActive ? 'Hoạt động' : 'Bị khoá',
                                            style: TextStyle(color: Colors.white, fontSize: 10),
                                          ),
                                          backgroundColor: isActive ? Colors.green : Colors.red,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                color: AppColors.navyDark,
                                onSelected: (v) {
                                  if (v == 'active') _toggleActive(u['id']);
                                  if (v == 'admin') _toggleAdmin(u['id']);
                                  if (v == 'delete') _delete(u['id']);
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(value: 'active',
                                      child: Text(isActive ? 'Khoá' : 'Mở khoá',
                                          style: const TextStyle(color: Colors.white))),
                                  PopupMenuItem(value: 'admin',
                                      child: Text(isAdmin ? 'Huỷ Admin' : 'Set Admin',
                                          style: const TextStyle(color: Colors.white))),
                                  const PopupMenuItem(value: 'delete',
                                      child: Text('Xóa', style: TextStyle(color: Colors.red))),
                                ],
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
