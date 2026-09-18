import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'widgets/badge_grid.dart';
import 'widgets/pdp_compliance_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Profil & Pencapaian',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                user?.name.isNotEmpty == true
                    ? user!.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.name ?? 'Muhammad Fazri',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status Kuota Akun (Free Tier)',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      Text(
                        '3 / 5 Sesi',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.6,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kuota harian di-reset setiap pukul 00:00 WIB. Upgrade ke Pro untuk sesi debat tanpa batas.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 10 Gamification Badges Grid
            const BadgeGrid(),

            const SizedBox(height: 24),

            // UU PDP Compliance Card
            PDPComplianceCard(
              onExportData: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Mengekspor arsip data debat dan profil Anda (format ZIP/JSON)...',
                    ),
                  ),
                );
              },
              onDeleteAccount: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Hapus Akun Permanen?',
                        style: TextStyle(color: Colors.white)),
                    content: const Text(
                      'Sesuai UU PDP Pasal 8, seluruh data profil, skor ELO, dan log transkrip debat Anda akan dihapus permanen dari basis data pgvector.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(authProvider.notifier).logout();
                          context.go('/login');
                        },
                        child: const Text('Hapus Permanen',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // Logout Action
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Keluar dari Akun'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
