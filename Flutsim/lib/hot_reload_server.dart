import 'dart:io';
import 'dart:convert';
import 'config.dart';

/// Dedicated hot reload server for instant UI updates
class HotReloadServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];

  Future<void> start() async {
    try {
      _server = await HttpServer.bind(
          InternetAddress.anyIPv4, FlutsimConfig.hotReloadPort);
      print(
          '🔥 Hot reload server started on port ${FlutsimConfig.hotReloadPort}');

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
      print('❌ Failed to start hot reload server: $e');
    }
  }

  void _handleWebSocket(WebSocket webSocket) {
    _clients.add(webSocket);
    print('🔥 Hot reload client connected. Total clients: ${_clients.length}');

    webSocket.listen(
      (data) {
        // Handle incoming messages if needed
        print('🔥 Hot reload message: $data');
      },
      onDone: () {
        _clients.remove(webSocket);
        print(
            '🔥 Hot reload client disconnected. Total clients: ${_clients.length}');
      },
      onError: (error) {
        print('❌ Hot reload WebSocket error: $error');
        _clients.remove(webSocket);
      },
    );
  }

  /// Trigger instant hot reload for all connected clients
  void triggerInstantHotReload() {
    if (_clients.isEmpty) {
      print('⚠️  No hot reload clients connected');
      return;
    }

    final hotReloadMessage = jsonEncode({
      'type': 'hot_reload',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'instant': true,
    });

    _clients.removeWhere((client) {
      try {
        client.add(hotReloadMessage);
        return false;
      } catch (e) {
        print('❌ Failed to send hot reload to client: $e');
        return true;
      }
    });

    print('🔥 Instant hot reload triggered for ${_clients.length} clients');
  }

  /// Send specific widget update
  void updateWidget(String widgetId, String newContent) {
    if (_clients.isEmpty) return;

    final updateMessage = jsonEncode({
      'type': 'widget_update',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'widgetId': widgetId,
      'content': newContent,
    });

    _clients.removeWhere((client) {
      try {
        client.add(updateMessage);
        return false;
      } catch (e) {
        print('❌ Failed to send widget update to client: $e');
        return true;
      }
    });

    print('🔥 Widget update sent for ${_clients.length} clients');
  }

  /// Send style update
  void updateStyles(String selector, Map<String, String> styles) {
    if (_clients.isEmpty) return;

    final updateMessage = jsonEncode({
      'type': 'style_update',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'selector': selector,
      'styles': styles,
    });

    _clients.removeWhere((client) {
      try {
        client.add(updateMessage);
        return false;
      } catch (e) {
        print('❌ Failed to send style update to client: $e');
        return true;
      }
    });

    print('🔥 Style update sent for ${_clients.length} clients');
  }

  void stop() {
    _server?.close();
    for (final client in _clients) {
      client.close();
    }
    _clients.clear();
    print('🔥 Hot reload server stopped');
  }
}
