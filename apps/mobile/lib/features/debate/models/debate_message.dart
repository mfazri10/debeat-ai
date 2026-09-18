class DebateMessage {
  final String id;
  final String speaker;
  final String text;
  final bool isAi;
  final int? score;
  final String? fallacy;
  final DateTime timestamp;

  DebateMessage({
    String? id,
    required this.speaker,
    required this.text,
    required this.isAi,
    this.score,
    this.fallacy,
    DateTime? timestamp,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'speaker': speaker,
        'text': text,
        'isAi': isAi,
        'score': score,
        'fallacy': fallacy,
        'timestamp': timestamp.toIso8601String(),
      };
}
