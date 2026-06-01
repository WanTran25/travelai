import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WriteReviewDialog extends StatefulWidget {
  final VoidCallback onDismiss;
  final void Function(int rating, String comment) onSubmit;

  const WriteReviewDialog({
    super.key,
    required this.onDismiss,
    required this.onSubmit,
  });

  @override
  State<WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<WriteReviewDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.card(context),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Gửi đánh giá của bạn',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starNum = i + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = starNum),
                icon: Icon(
                  Icons.star,
                  color: starNum <= _rating ? const Color(0xFFFFD700) : AppColors.secondaryText(context),
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Hãy chia sẻ trải nghiệm tuyệt vời của bạn...',
              hintStyle: TextStyle(color: AppColors.secondaryText(context)),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.accentOrange),
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.fieldBorder(context)),
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: TextStyle(color: AppColors.primaryText(context)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onDismiss,
                child: Text('Hủy bỏ', style: TextStyle(color: AppColors.secondaryText(context))),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_commentController.text.trim().isNotEmpty) {
                    widget.onSubmit(_rating, _commentController.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Gửi đi', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
