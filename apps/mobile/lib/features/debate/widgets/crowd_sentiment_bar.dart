import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CrowdSentimentBar extends StatelessWidget {
  final int sentimentPercent; // 0 - 100
  final String activeReaction;
  final String latestComment;

  const CrowdSentimentBar({
    super.key,
    required this.sentimentPercent,
    required this.activeReaction,
    required this.latestComment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt_outlined,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              const Text(
                'Sentimen Penonton Live:',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const Spacer(),
              Text(
                '$activeReaction $sentimentPercent% Positif',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (sentimentPercent / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.success),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 11, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  latestComment,
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
