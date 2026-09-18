import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/debate_message.dart';

class DebateSpeechBubble extends StatelessWidget {
  final DebateMessage message;

  const DebateSpeechBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isAi = message.isAi;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAi) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceLight,
              child: const Icon(Icons.smart_toy,
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isAi
                    ? AppColors.surface
                    : AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isAi ? 4 : 16),
                  bottomRight: Radius.circular(isAi ? 16 : 4),
                ),
                border: Border.all(
                  color: isAi
                      ? AppColors.border
                      : AppColors.primary.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.speaker,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isAi ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                      if (message.score != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Skor: ${message.score}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  if (message.fallacy != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Fallacy: ${message.fallacy}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!isAi) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
