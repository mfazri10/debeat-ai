import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  String _selectedTopic = 'Dewan ini akan mewajibkan adopsi AI pada kurikulum pendidikan tinggi nasional.';
  String _selectedFormat = 'KDMI';
  String _selectedStance = 'PRO';
  String _selectedPersona = 'Presiden RI';
  int _totalRounds = 3;
  int _timePerTurn = 300;

  final List<String> _sampleMotions = [
    'Dewan ini akan mewajibkan adopsi AI pada kurikulum pendidikan tinggi nasional.',
    'Dewan ini percaya subsidi kendaraan listrik memperlebar kesenjangan ekonomi.',
    'Dewan ini akan melarang algoritma media sosial yang memicu kemarahan publik.',
    'This House would ban commercial development of autonomous AI weapons.',
    'This House believes universal basic income should replace conditional welfare.',
  ];

  final List<Map<String, String>> _personas = [
    {'name': 'Presiden RI', 'desc': 'Diplomatis, stabilitas nasional, berwibawa'},
    {'name': 'Menteri Keuangan', 'desc': 'Rasional, data fiskal & disiplin APBN'},
    {'name': 'Hakim MK', 'desc': 'Hukum konstitusi, hak asasi & keadilan'},
    {'name': 'Aktivis Lingkungan', 'desc': 'Urgensi krisis iklim & keadilan sosial'},
    {'name': 'Silicon Valley CEO', 'desc': 'Disrupsi AI, pasar bebas & masa depan'},
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.mic, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'DebateAI Lobby',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User ELO & Quota Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${user?.name ?? "Debater"}!',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rating ELO: ${user?.eloRating ?? 1000} · Poin: ${user?.totalPoints ?? 0}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Free: 3/5 Sesi',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              '1. Pilih Mosi Debat',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._sampleMotions.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedTopic = m),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _selectedTopic == m
                          ? AppColors.primary.withOpacity(0.12)
                          : AppColors.surface,
                      border: Border.Border.all(
                        color: _selectedTopic == m
                            ? AppColors.primary
                            : AppColors.border,
                        width: _selectedTopic == m ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      m,
                      style: TextStyle(
                        fontSize: 13,
                        color: _selectedTopic == m ? Colors.white : AppColors.textSecondary,
                        fontWeight: _selectedTopic == m ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              '2. Posisi Anda (Stance)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedStance = 'PRO'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedStance == 'PRO'
                            ? AppColors.pro.withOpacity(0.15)
                            : AppColors.surface,
                        border: Border.Border.all(
                          color: _selectedStance == 'PRO' ? AppColors.pro : AppColors.border,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'PRO (Pemerintah / Afirmatif)',
                        style: TextStyle(
                          color: _selectedStance == 'PRO' ? AppColors.pro : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedStance = 'CONTRA'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedStance == 'CONTRA'
                            ? AppColors.contra.withOpacity(0.15)
                            : AppColors.surface,
                        border: Border.Border.all(
                          color: _selectedStance == 'CONTRA' ? AppColors.contra : AppColors.border,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'KONTRA (Oposisi)',
                        style: TextStyle(
                          color: _selectedStance == 'CONTRA' ? AppColors.contra : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              '3. Lawan Debat AI (Persona)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 115,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _personas.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final p = _personas[i];
                  final isSelected = _selectedPersona == p['name'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPersona = p['name']!),
                    child: Container(
                      width: 160,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                        border: Border.Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['name']!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p['desc']!,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to real-time debate arena
                  context.push(
                    '/arena/mock-session-001',
                    extra: {
                      'topic': _selectedTopic,
                      'stance': _selectedStance,
                      'persona': _selectedPersona,
                      'format': _selectedFormat,
                    },
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, size: 22),
                    SizedBox(width: 8),
                    Text('Mulai Sesi Debat Sekarang', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
