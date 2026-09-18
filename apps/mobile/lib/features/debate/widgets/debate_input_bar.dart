import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DebateInputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isAiSpeaking;
  final VoidCallback onSubmit;

  const DebateInputBar({
    super.key,
    required this.controller,
    required this.isAiSpeaking,
    required this.onSubmit,
  });

  @override
  State<DebateInputBar> createState() => _DebateInputBarState();
}

class _DebateInputBarState extends State<DebateInputBar> {
  bool _isListening = false;

  void _toggleMic() {
    setState(() => _isListening = !_isListening);
    if (_isListening) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mendengarkan suara Anda via Speech-to-Text Whisper...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: widget.isAiSpeaking ? null : _toggleMic,
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? AppColors.error : AppColors.primary,
              ),
              tooltip: 'Bicara (Voice Input)',
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                enabled: !widget.isAiSpeaking,
                maxLines: null,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: widget.isAiSpeaking
                      ? 'Menunggu giliran lawan AI...'
                      : 'Ketik argumen atau sanggahan Anda...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: widget.isAiSpeaking ? null : widget.onSubmit,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.surfaceLight,
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
