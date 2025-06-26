import 'dart:io';
import 'dart:convert';
import 'config.dart';

/// Dedicated auto reload server for browser refresh
class AutoReloadServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];

  Future<void> start() async {
    try {
      _server = await HttpServer.bind(
          InternetAddress.anyIPv4, FlutsimConfig.autoReloadPort);
      print(
          '🔄 Auto reload server started on port ${FlutsimConfig.autoReloadPort}');

      _server!.listen((HttpRequest request) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocketTransformer.upgrade(request).then((WebSocket webSocket) {
            _handleWebSocket(webSocket);
          });
        } else {
          request.response.statusCode = 400;
          request.response.close();
        }
      });
    } catch (e) {
      print('❌ Failed to start auto reload server: $e');
    }
  }

  void _handleWebSocket(WebSocket webSocket) {
    _clients.add(webSocket);
    print('🔄 Auto reload client connected. Total clients: ${_clients.length}');

    webSocket.listen(
      (data) {
        print('🔄 Auto reload message: $data');
      },
      onDone: () {
        _clients.remove(webSocket);
        print(
            '🔄 Auto reload client disconnected. Total clients: ${_clients.length}');
      },
      onError: (error) {
        print('❌ Auto reload WebSocket error: $error');
        _clients.remove(webSocket);
      },
    );
  }

  /// Trigger auto reload for all connected browsers
  void triggerAutoReload() {
    if (_clients.isEmpty) {
      print('⚠️  No auto reload clients connected');
      return;
    }

    final autoReloadMessage = jsonEncode({
      'type': 'auto_reload',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _clients.removeWhere((client) {
      try {
        client.add(autoReloadMessage);
        return false;
      } catch (e) {
        print('❌ Failed to send auto reload to client: $e');
        return true;
      }
    });

    print('🔄 Auto reload triggered for ${_clients.length} browsers');
  }

  void stop() {
    _server?.close();
    for (final client in _clients) {
      client.close();
    }
    _clients.clear();
    print('🔄 Auto reload server stopped');
  }
}
