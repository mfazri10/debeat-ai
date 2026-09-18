import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class BadgeItem {
  final String title;
  final String desc;
  final IconData icon;
  final bool isUnlocked;

  const BadgeItem({
    required this.title,
    required this.desc,
    required this.icon,
    required this.isUnlocked,
  });
}

class BadgeGrid extends StatelessWidget {
  const BadgeGrid({super.key});

  final List<BadgeItem> _badges = const [
    BadgeItem(
      title: 'Logika Emas',
      desc: 'Skor Logika > 90 dalam 3 ronde berturut-turut',
      icon: Icons.psychology,
      isUnlocked: true,
    ),
    BadgeItem(
      title: 'Anti Fallacy',
      desc: 'Menyelesaikan debat tanpa satupun Logical Fallacy',
      icon: Icons.shield,
      isUnlocked: true,
    ),
    BadgeItem(
      title: 'Debater Kilat',
      desc: 'Menjawab sanggahan lawan dalam waktu < 45 detik',
      icon: Icons.flash_on,
      isUnlocked: true,
    ),
    BadgeItem(
      title: 'Retorika Tajam',
      desc: 'Skor Retorika > 85 dari Juri 2',
      icon: Icons.record_voice_over,
      isUnlocked: true,
    ),
    BadgeItem(
      title: 'Juara KDMI',
      desc: 'Memenangkan 10 sesi dengan format KDMI',
      icon: Icons.emoji_events,
      isUnlocked: false,
    ),
    BadgeItem(
      title: 'Diplomat Ulung',
      desc: 'Menghadapi Persona AI Presiden RI & Menkeu',
      icon: Icons.public,
      isUnlocked: false,
    ),
    BadgeItem(
      title: 'Master WUDC',
      desc: 'Mencapai status Closing Half di format WUDC',
      icon: Icons.school,
      isUnlocked: false,
    ),
    BadgeItem(
      title: 'Suara Rakyat',
      desc: 'Mencapai sentimen penonton 95% positif',
      icon: Icons.favorite,
      isUnlocked: false,
    ),
    BadgeItem(
      title: 'RAG Ingestor',
      desc: 'Menyumbang 5 dokumen referensi yang disetujui',
      icon: Icons.file_upload,
      isUnlocked: false,
    ),
    BadgeItem(
      title: 'Grandmaster ELO',
      desc: 'Mencapai rating ELO di atas 2,000 poin',
      icon: Icons.military_tech,
      isUnlocked: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lencana Prestasi (10 Gamification Badges)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
          ),
          itemCount: _badges.length,
          itemBuilder: (context, index) {
            final badge = _badges[index];
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badge.isUnlocked
                    ? AppColors.surface
                    : AppColors.surface.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: badge.isUnlocked
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.border.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: badge.isUnlocked
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.white10,
                    child: Icon(
                      badge.icon,
                      size: 18,
                      color: badge.isUnlocked
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          badge.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: badge.isUnlocked
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          badge.desc,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
