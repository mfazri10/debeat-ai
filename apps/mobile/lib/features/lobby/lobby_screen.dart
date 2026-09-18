import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'widgets/user_stat_card.dart';
import 'widgets/motion_picker.dart';
import 'widgets/persona_slider.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  String _selectedTopic =
      'Dewan ini akan mewajibkan adopsi AI pada kurikulum pendidikan tinggi nasional.';
  String _selectedFormat = 'KDMI';
  String _selectedStance = 'PRO';
  String _selectedPersona = 'Presiden RI';

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

  void _startDebate() {
    final sessionId = 'deb-${DateTime.now().millisecondsSinceEpoch % 10000}';
    context.push('/arena/$sessionId', extra: {
      'topic': _selectedTopic,
      'format': _selectedFormat,
      'stance': _selectedStance,
      'persona': _selectedPersona,
    });
  }

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
              'DeBeat.AI Lobby',
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
            UserStatCard(user: user),

            const SizedBox(height: 24),

            // Motion & Format Picker
            MotionPicker(
              sampleMotions: _sampleMotions,
              selectedMotion: _selectedTopic,
              selectedFormat: _selectedFormat,
              selectedStance: _selectedStance,
              onMotionSelected: (m) => setState(() => _selectedTopic = m),
              onFormatSelected: (f) => setState(() => _selectedFormat = f),
              onStanceSelected: (s) => setState(() => _selectedStance = s),
            ),

            const SizedBox(height: 24),

            // AI Persona Slider
            PersonaSlider(
              personas: _personas,
              selectedPersona: _selectedPersona,
              onPersonaSelected: (p) => setState(() => _selectedPersona = p),
            ),

            const SizedBox(height: 32),

            // Launch Arena CTA Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _startDebate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Mulai Debat Real-Time',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
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
