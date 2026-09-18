import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final badges = [
      {'code': 'first_debate', 'title': 'Debater Pertama', 'icon': '🎯', 'unlocked': true},
      {'code': 'first_win', 'title': 'Kemenangan Perdana', 'icon': '🏆', 'unlocked': true},
      {'code': 'streak_3', 'title': 'Hat-trick (3x Menang)', 'icon': '🔥', 'unlocked': true},
      {'code': 'points_100', 'title': 'Debater Resmi', 'icon': '⭐', 'unlocked': true},
      {'code': 'streak_5', 'title': 'Unstoppable (5x Menang)', 'icon': '⚡', 'unlocked': false},
      {'code': 'perfect_score', 'title': 'Skor Sempurna 95+', 'icon': '💎', 'unlocked': false},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Profil & Statistik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Avatar & Name
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.name ?? 'Muhammad Fazri',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? 'muhammadfazri10@gmail.com',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),

            const SizedBox(height: 24),

            // Daily Quota Card (Free Tier)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      const Text('Kuota Sesi Harian (Free Tier)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('3/5 Sesi Tersisa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 3 / 5,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reset otomatis setiap pukul 00:00 WIB. Upgrade ke PRO untuk sesi tak terbatas.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Badges Grid
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('Lencana Pencapaian (Badges)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: badges.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, i) {
                final b = badges[i];
                final unlocked = b['unlocked'] as bool;
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: unlocked ? AppColors.surface : AppColors.surface.withOpacity(0.4),
                    border: Border.all(
                      color: unlocked ? AppColors.primary.withOpacity(0.4) : AppColors.border,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        b['icon'] as String,
                        style: TextStyle(
                          fontSize: 28,
                          color: unlocked ? null : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: unlocked ? Colors.white : AppColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // UU PDP: Export Data Button
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mengunduh seluruh arsip data akun Anda (UU PDP Compliance)...'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export Data Saya (UU PDP)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Logout Button
            TextButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.danger, size: 18),
              label: const Text('Keluar dari Akun', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      ),
    );
  }
}
