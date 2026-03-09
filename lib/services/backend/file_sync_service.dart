import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/utils/logger.dart';

class FileSyncService {
  FileSyncService._();
  static final instance = FileSyncService._();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _controller.stream;

  Future<void> connect(String backendUrl) async {
    final wsUrl = backendUrl.replaceFirst('http', 'ws');
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/ws/files'));
      _sub = _channel!.stream.listen(
        (data) {
          final decoded = jsonDecode(data as String) as Map<String, dynamic>;
          _controller.add(decoded);
        },
        onError: (Object error) {
          AppLogger.error('WebSocket error', error);
        },
        onDone: () {
          AppLogger.warning('WebSocket closed, reconnecting...');
          _reconnect(backendUrl);
        },
      );
    } catch (e) {
      AppLogger.error('WebSocket connection failed', e);
    }
  }

  Future<void> _reconnect(String backendUrl) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    await connect(backendUrl);
  }

  void send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    await _channel?.sink.close();
  }
}
