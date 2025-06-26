import 'dart:io';
import 'dart:convert';
import 'config.dart';

class LiveReloadServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];

  Future<void> start() async {
    try {
      _server = await HttpServer.bind(
          InternetAddress.anyIPv4, FlutsimConfig.liveReloadPort);
      print(
          '🔌 Live reload server started on port ${FlutsimConfig.liveReloadPort}');

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
      print('❌ Failed to start live reload server: $e');
    }
  }

  void _handleWebSocket(WebSocket webSocket) {
    _clients.add(webSocket);
    print('📱 Client connected. Total clients: ${_clients.length}');

    webSocket.listen(
      (data) {
        // Handle incoming messages if needed
        print('📨 Received: $data');
      },
      onDone: () {
        _clients.remove(webSocket);
        print('📱 Client disconnected. Total clients: ${_clients.length}');
      },
      onError: (error) {
        print('❌ WebSocket error: $error');
        _clients.remove(webSocket);
      },
    );
  }

  void triggerReload() {
    if (_clients.isEmpty) {
      print('⚠️  No clients connected for live reload');
      return;
    }

    final reloadMessage = jsonEncode({
      'type': 'reload',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _clients.removeWhere((client) {
      try {
        client.add(reloadMessage);
        return false;
      } catch (e) {
        print('❌ Failed to send reload to client: $e');
        return true;
      }
    });

    print('🔄 Live reload triggered for ${_clients.length} clients');
  }

  void stop() {
    _server?.close();
    for (final client in _clients) {
      client.close();
    }
    _clients.clear();
    print('🔌 Live reload server stopped');
  }
}
