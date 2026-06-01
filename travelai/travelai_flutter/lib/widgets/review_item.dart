import 'dart:io' show File;
import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'proxied_image.dart';

const _reactionEmojis = {
  'like': '👍',
  'love': '❤️',
  'laugh': '😂',
  'cry': '😢',
  'angry': '😡',
};

class ReviewItem extends StatefulWidget {
  final Review review;

  const ReviewItem({super.key, required this.review});

  @override
  State<ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<ReviewItem> {
  late Map<String, int> _reactionCounts;
  String? _userReaction;

  @override
  void initState() {
    super.initState();
    _reactionCounts = Map.from(widget.review.reactionCounts);
    _userReaction = widget.review.userReaction;
  }

  Future<void> _toggleReaction(String reaction) async {
    final result = await ApiService.reactToReview(widget.review.id, reaction);
    if (result != null && mounted) {
      final newReaction = result['reaction'] as String?;
      setState(() {
        if (_userReaction != null && _userReaction == newReaction) {
          _reactionCounts[_userReaction!] = (_reactionCounts[_userReaction!] ?? 1) - 1;
          if (_reactionCounts[_userReaction!]! <= 0) _reactionCounts.remove(_userReaction!);
          _userReaction = null;
        } else {
          if (_userReaction != null) {
            _reactionCounts[_userReaction!] = (_reactionCounts[_userReaction!] ?? 1) - 1;
            if (_reactionCounts[_userReaction!]! <= 0) _reactionCounts.remove(_userReaction!);
          }
          if (newReaction != null) {
            _reactionCounts[newReaction] = (_reactionCounts[newReaction] ?? 0) + 1;
          }
          _userReaction = newReaction;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.card(context).withAlpha(153),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/profile', arguments: review.userId),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  _buildAvatar(review),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.userName,
                          style: TextStyle(
                            color: AppColors.primaryText(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        color: i < review.rating
                            ? const Color(0xFFFFD700)
                            : AppColors.secondaryText(context).withAlpha(128),
                        size: 14,
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              review.comment,
              style: TextStyle(
                color: AppColors.primaryText(context).withOpacity(0.85),
                fontSize: 12,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            _buildReactionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Review review) {
    if (review.userAvatar == null || review.userAvatar!.isEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.accentOrange.withAlpha(40),
        child: Text(
          review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.accentOrange,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    ImageProvider avatarImage;
    if (review.userAvatar!.startsWith('http://') || review.userAvatar!.startsWith('https://')) {
      avatarImage = proxiedNetworkImageProvider(review.userAvatar!);
    } else {
      try {
        if (File(review.userAvatar!).existsSync()) {
          avatarImage = FileImage(File(review.userAvatar!));
        } else {
          avatarImage = proxiedNetworkImageProvider(review.userAvatar!);
        }
      } catch (_) {
        avatarImage = proxiedNetworkImageProvider(review.userAvatar!);
      }
    }

    return CircleAvatar(
      radius: 14,
      backgroundImage: avatarImage,
      backgroundColor: AppColors.card(context),
    );
  }

  Widget _buildReactionBar() {
    return Row(
      children: [
        ..._reactionEmojis.entries.map((entry) {
          final emoji = entry.key;
          final displayEmoji = entry.value;
          final count = _reactionCounts[emoji] ?? 0;
          final isActive = _userReaction == emoji;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggleReaction(emoji),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.accentOrange.withAlpha(40)
                        : AppColors.primaryText(context).withAlpha(12),
                    borderRadius: BorderRadius.circular(12),
                    border: isActive
                        ? Border.all(color: AppColors.accentOrange.withAlpha(80))
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(displayEmoji, style: const TextStyle(fontSize: 13)),
                      if (count > 0) ...[
                        const SizedBox(width: 3),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive ? AppColors.accentOrange : Colors.white70,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        if (widget.review.createdAt > 0)
          Text(
            _formatTime(widget.review.createdAt),
            style: TextStyle(color: AppColors.secondaryText(context), fontSize: 9),
          ),
      ],
    );
  }

  String _formatTime(int ms) {
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ms),
    );
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes}p';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${diff.inDays ~/ 7}t';
  }
}
