import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class DebateMessage {
  final String speaker;
  final String text;
  final bool isAi;
  final int? score;
  final String? fallacy;

  DebateMessage({
    required this.speaker,
    required this.text,
    required this.isAi,
    this.score,
    this.fallacy,
  });
}

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

  // Skor 3 Juri Terakhir
  int _scoreLogika = 82;
  int _scoreRetorika = 78;
  int _scoreDampak = 85;
  String? _detectedFallacy;

  // Reaksi Penonton
  String _activeReaction = '👏';
  int _audienceSentiment = 75; // 0 - 100
  String _latestCrowdComment = '“Analogi pendidikan tingginya sangat mengena!”';

  final List<DebateMessage> _messages = [
    DebateMessage(
      speaker: 'Moderator AI',
      text: 'Selamat datang di Arena Debat. Mosi ronde ini: "Dewan ini akan mewajibkan adopsi AI pada kurikulum pendidikan tinggi nasional". Giliran pembicara afirmatif (User) dipersilakan.',
      isAi: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
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
    });

    _scrollToBottom();

    // Simulasi respons AI streaming via gRPC
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _isAiSpeaking = false;
        _messages.add(
          DebateMessage(
            speaker: widget.initialData?['persona'] ?? 'Presiden RI',
            text: 'Terima kasih atas argumen Saudara. Namun, kita tidak boleh mengabaikan disparitas infrastruktur digital antara universitas di kota besar dan daerah 3T. Kewajiban prematur justru memperlebar kesenjangan mutu pendidikan nasional.',
            isAi: true,
            score: 88,
          ),
        );
        _scoreLogika = 88;
        _scoreRetorika = 85;
        _scoreDampak = 90;
        _activeReaction = '😲';
        _audienceSentiment = 82;
        _latestCrowdComment = '“Bantahan telak mengenai infrastruktur 3T!”';
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.initialData?['topic'] ??
        'Dewan ini akan mewajibkan adopsi AI pada kurikulum nasional.';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Ronde $_currentRound/$_totalRounds',
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sisa: ${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              topic,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: AppColors.danger),
            tooltip: 'Selesai Debat',
            onPressed: () {
              context.pushReplacement('/results/${widget.sessionId}');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Live Audience & Judges Telemetry Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0C1322),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 3 AI Judges Scores
                Row(
                  children: [
                    _buildJudgeBadge('⚖️ Logika', _scoreLogika),
                    const SizedBox(width: 6),
                    _buildJudgeBadge('🎭 Retorika', _scoreRetorika),
                    const SizedBox(width: 6),
                    _buildJudgeBadge('🌏 Dampak', _scoreDampak),
                  ],
                ),
                // Live Audience Reaction Emoji
                Row(
                  children: [
                    Text(_activeReaction, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 4),
                    Text(
                      '$_audienceSentiment%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Live crowd comment ticker
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: AppColors.surface,
            child: Text(
              'Penonton: $_latestCrowdComment',
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 2. Transcripts / Speech Bubbles
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isMe = !m.isAi;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment:
                        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            m.speaker,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isMe ? AppColors.primaryLight : AppColors.secondary,
                            ),
                          ),
                          if (m.score != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.emerald.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Skor: ${m.score}',
                                style: const TextStyle(fontSize: 10, color: AppColors.success),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.82,
                        ),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.primary.withOpacity(0.2)
                              : AppColors.surface,
                          border: Border.all(
                            color: isMe ? AppColors.primary : AppColors.border,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                        ),
                        child: Text(
                          m.text,
                          style: const TextStyle(fontSize: 14, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Typing indicator jika AI berpikir
          if (_isAiSpeaking)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.initialData?['persona'] ?? "AI"} sedang menyusun argumen bantahan...',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

          // 3. Input Argumen & Mic Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitArgument(),
                      decoration: InputDecoration(
                        hintText: 'Tuliskan butir argumen Anda...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic, color: AppColors.secondary),
                    tooltip: 'Bicara (Voice to Text)',
                    onPressed: () {
                      _textController.text =
                          'Berdasarkan data riset UNESCO, kurikulum berbasis AI meningkatkan efisiensi belajar hingga 40%.';
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: _submitArgument,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJudgeBadge(String title, int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
