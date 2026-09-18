import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class ResultsScreen extends StatelessWidget {
  final String sessionId;

  const ResultsScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Hasil & Evaluasi Debat',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Winner Trophy Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 54),
                  const SizedBox(height: 8),
                  const Text(
                    'KEMENANGAN TELAK!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.black,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Skor Anda: 86.4 vs AI Lawan: 81.2',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.trending_up, color: AppColors.success, size: 18),
                            SizedBox(width: 4),
                            Text(
                              '+24 ELO Rating',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
                            SizedBox(width: 4),
                            Text(
                              '+15 Poin Gamifikasi',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Score Breakdown by Judges
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Breakdown Skor Dewan Juri AI',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  _buildScoreRow('Validitas Logika & Fallacy Detector', 88, AppColors.primaryLight),
                  _buildScoreRow('Kekuatan Bukti & Data Kontekstual', 80, AppColors.success),
                  _buildScoreRow('Teknik Retorika & Persuasif', 84, AppColors.secondary),
                  _buildScoreRow('Responsivitas Bantahan', 90, AppColors.accent),
                  _buildScoreRow('Kejelasan Struktur PREP', 86, Colors.amber),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. AI Coach Feedback
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology, color: AppColors.secondary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Evaluasi Pelatih AI',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '“Poin afirmatif Anda mengenai percepatan digitalisasi sangat tajam dan didukung data UNESCO yang valid. Untuk debat berikutnya, perkuat argumen mitigasi biaya implementasi di universitas swasta agar lawan tidak memiliki celah sanggahan.”',
                    style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Return to Lobby Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => context.go('/lobby'),
                child: const Text('Kembali ke Lobby', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, int score, Color barColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.between,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('$score/100', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
