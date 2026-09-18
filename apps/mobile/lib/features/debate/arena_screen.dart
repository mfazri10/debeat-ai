import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'models/debate_message.dart';
import 'widgets/scorecard_overlay.dart';
import 'widgets/crowd_sentiment_bar.dart';
import 'widgets/debate_speech_bubble.dart';
import 'widgets/debate_input_bar.dart';

class ArenaScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final Map<String, dynamic>? initialData;

  const ArenaScreen({
    super.key,
    required this.sessionId,
    this.initialData,
  });

  @override
  ConsumerState<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends ConsumerState<ArenaScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _currentRound = 1;
  final int _totalRounds = 3;
  int _secondsLeft = 180;
  Timer? _timer;
  bool _isAiSpeaking = false;

  // Skor 3 Juri AI
  int _scoreLogika = 82;
  int _scoreRetorika = 78;
  int _scoreDampak = 85;
  String? _detectedFallacy;

  // Sentimen Penonton Live
  final String _activeReaction = '👏';
  int _audienceSentiment = 75;
  String _latestCrowdComment = '“Analogi pendidikan tingginya sangat mengena!”';

  late final List<DebateMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      DebateMessage(
        speaker: 'Moderator AI',
        text:
            'Selamat datang di Arena Debat. Mosi: "Dewan ini akan mewajibkan adopsi AI pada kurikulum pendidikan tinggi nasional". Giliran pembicara afirmatif (User) dipersilakan.',
        isAi: true,
      ),
    ];
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitArgument() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        DebateMessage(
          speaker: 'Anda (Afirmatif)',
          text: text,
          isAi: false,
          score: 84,
        ),
      );
      _textController.clear();
      _isAiSpeaking = true;
      _scoreLogika = 86;
      _scoreRetorika = 81;
      _scoreDampak = 88;
      _audienceSentiment = 82;
      _latestCrowdComment = '“Data empiris yang diajukan kuat sekali.”';
    });
    _scrollToBottom();

    // AI Opponent counter-speech simulation (Microservice gRPC)
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          DebateMessage(
            speaker: 'Lawan (Oposisi AI - Presiden RI)',
            text:
                'Saudara pembicara melupakan disparitas infrastruktur digital di wilayah 3T. Kewajiban kurikulum AI secara terburu-buru tanpa pemerataan listrik dan internet hanya akan memperlebar jurang ketimpangan antardaerah.',
            isAi: true,
            score: 88,
            fallacy: 'Hasty Generalization (Terklarifikasi)',
          ),
        );
        _isAiSpeaking = false;
        _detectedFallacy = 'Hasty Generalization (Lawan menguji premis Anda)';
        _audienceSentiment = 79;
        _latestCrowdComment = '“Sanggahan oposisi tepat sasaran pada isu keadilan sosial!”';
      });
      _scrollToBottom();
    });
  }

  void _finishDebate() {
    context.pushReplacement('/results/${widget.sessionId}', extra: {
      'scoreLogika': _scoreLogika,
      'scoreRetorika': _scoreRetorika,
      'scoreDampak': _scoreDampak,
      'totalScore': ((_scoreLogika + _scoreRetorika + _scoreDampak) / 3).round(),
      'eloChange': '+24',
      'winner': 'Afirmatif (Anda)',
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('Tinggalkan Arena?',
                    style: TextStyle(color: Colors.white)),
                content: const Text(
                  'Jika keluar saat debat berlangsung, penalti ELO dapat dikenakan.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Lanjutkan Debat'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.pop();
                    },
                    child: const Text('Keluar',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            );
          },
        ),
        title: Column(
          children: [
            Text(
              'Ronde $_currentRound / $_totalRounds',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 12, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  '$minutes:$seconds',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: AppColors.warning),
            tooltip: 'Selesaikan & Evaluasi Juri',
            onPressed: _finishDebate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Floating 3-Judges Scorecard
          ScorecardOverlay(
            scoreLogika: _scoreLogika,
            scoreRetorika: _scoreRetorika,
            scoreDampak: _scoreDampak,
            detectedFallacy: _detectedFallacy,
          ),

          // Live Crowd Sentiment Gauge
          CrowdSentimentBar(
            sentimentPercent: _audienceSentiment,
            activeReaction: _activeReaction,
            latestComment: _latestCrowdComment,
          ),

          // Debate Messages Feed
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return DebateSpeechBubble(message: _messages[index]);
              },
            ),
          ),

          // Speech Input Bar
          DebateInputBar(
            controller: _textController,
            isAiSpeaking: _isAiSpeaking,
            onSubmit: _submitArgument,
          ),
        ],
      ),
    );
  }
}
