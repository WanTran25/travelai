import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  List<dynamic> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getAdminReviews();
    if (mounted) setState(() { _reviews = data; _loading = false; });
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        title: Text('Xác nhận', style: TextStyle(color: AppColors.primaryText(context))),
        content: const Text('Xóa đánh giá này?', style: TextStyle(color: Colors.grey)),
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
      await ApiService.deleteAdminReview(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text('Quản lý Đánh giá',
            style: TextStyle(color: AppColors.primaryText(context), fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.appBar(context),
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentOrange))
          : _reviews.isEmpty
              ? Center(child: Text('Chưa có đánh giá', style: TextStyle(color: AppColors.secondaryText(context))))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reviews.length,
                    itemBuilder: (context, i) {
                      final r = _reviews[i];
                      final user = r['user'] as Map<String, dynamic>?;
                      final place = r['place'] as Map<String, dynamic>?;
                      return Card(
                        color: AppColors.card(context),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(user?['name'] ?? 'Unknown',
                                      style: TextStyle(color: AppColors.primaryText(context), fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Row(
                                    children: List.generate(5, (j) => Icon(
                                      Icons.star,
                                      color: j < (r['rating'] ?? 0) ? const Color(0xFFFFD700) : AppColors.secondaryText(context).withAlpha(128),
                                      size: 14,
                                    )),
                                  ),
                                ],
                              ),
                              if (place != null)
                                Text('Địa điểm: ${place['name']}',
                                    style: TextStyle(color: AppColors.secondaryText(context), fontSize: 11)),
                              const SizedBox(height: 6),
                              Text(r['comment'] ?? '',
                                  style: const TextStyle(color: Color(0xFFE3E4EB), fontSize: 13)),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _delete(r['id']),
                                ),
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
