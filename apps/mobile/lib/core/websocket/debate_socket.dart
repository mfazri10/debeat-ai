import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_endpoints.dart';

enum DebateSocketState { disconnected, connecting, connected, error }

class DebateSocketService {
  WebSocketChannel? _channel;
  DebateSocketState _state = DebateSocketState.disconnected;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  DebateSocketState get state => _state;

  void connect(String sessionId, String token) {
    try {
      _state = DebateSocketState.connecting;
      final uri = Uri.parse(ApiEndpoints.debateWebSocket(sessionId, token));
      _channel = WebSocketChannel.connect(uri);
      _state = DebateSocketState.connected;

      _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String) as Map<String, dynamic>;
            _messageController.add(decoded);
          } catch (e) {
            // Raw text or non-json message
          }
        },
        onError: (err) {
          _state = DebateSocketState.error;
        },
        onDone: () {
          _state = DebateSocketState.disconnected;
        },
      );
    } catch (e) {
      _state = DebateSocketState.error;
    }
  }

  void sendArgument({
    required String sessionId,
    required String content,
    String contentType = 'TEXT',
  }) {
    if (_channel != null && _state == DebateSocketState.connected) {
      final payload = jsonEncode({
        'action': 'argument',
        'session_id': sessionId,
        'content': content,
        'content_type': contentType,
      });
      _channel!.sink.add(payload);
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _state = DebateSocketState.disconnected;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
