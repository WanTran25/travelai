import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminAiLogScreen extends StatefulWidget {
  const AdminAiLogScreen({super.key});

  @override
  State<AdminAiLogScreen> createState() => _AdminAiLogScreenState();
}

class _AdminAiLogScreenState extends State<AdminAiLogScreen> {
  List<dynamic> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getAdminAiLogs();
    if (mounted) setState(() { _logs = data; _loading = false; });
  }

  void _showDetail(Map<String, dynamic> log) {
    final user = log['user'] as Map<String, dynamic>?;
    String responseStr = '{}';
    try {
      final resp = log['ai_response'];
      responseStr = const JsonEncoder.withIndent('  ').convert(resp is String ? jsonDecode(resp) : resp);
    } catch (_) {}

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        title: Text('Chi tiết AI Log', style: TextStyle(color: AppColors.primaryText(context))),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('User: ${user?['name'] ?? 'Guest'}',
                  style: TextStyle(color: AppColors.secondaryText(context), fontSize: 12)),
              const SizedBox(height: 8),
              Text('Prompt:', style: TextStyle(color: AppColors.primaryText(context), fontWeight: FontWeight.bold)),
              Text(log['user_prompt'] ?? '',
                  style: const TextStyle(color: Color(0xFFE3E4EB), fontSize: 13)),
              const SizedBox(height: 12),
              Text('Response:', style: TextStyle(color: AppColors.primaryText(context), fontWeight: FontWeight.bold)),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(responseStr,
                    style: const TextStyle(color: Colors.green, fontSize: 11, fontFamily: 'monospace')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text('AI Suggestions Logs',
            style: TextStyle(color: AppColors.primaryText(context), fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.appBar(context),
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentOrange))
          : _logs.isEmpty
              ? Center(child: Text('Chưa có AI logs', style: TextStyle(color: AppColors.secondaryText(context))))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, i) {
                      final log = _logs[i];
                      final user = log['user'] as Map<String, dynamic>?;
                      return Card(
                        color: AppColors.card(context),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.auto_awesome, color: AppColors.accentOrange),
                          title: Text(
                             ((log['user_prompt'] as String?)?.length ?? 0) > 60
                                ? '${(log['user_prompt'] as String?)?.substring(0, 60)}...'
                                : log['user_prompt'] ?? '',
                            style: TextStyle(color: AppColors.primaryText(context), fontSize: 13),
                          ),
                          subtitle: Text(
                            'User: ${user?['name'] ?? 'Guest'}',
                            style: TextStyle(color: AppColors.secondaryText(context), fontSize: 11),
                          ),
                          trailing: Icon(Icons.chevron_right, color: AppColors.secondaryText(context)),
                          onTap: () => _showDetail(log),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
